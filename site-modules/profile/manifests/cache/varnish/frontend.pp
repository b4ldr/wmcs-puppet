class profile::cache::varnish::frontend (
    Hash[String, Hash] $cache_nodes = lookup('cache::nodes'),
    String $cache_cluster = lookup('cache::cluster'),
    String $conftool_prefix = lookup('conftool_prefix'),
    Hash[String, Any] $fe_vcl_config = lookup('profile::cache::varnish::frontend::fe_vcl_config'),
    Hash[String, Any] $fe_cache_be_opts = lookup('profile::cache::varnish::cache_be_opts'),
    Boolean $backends_in_etcd = lookup('profile::cache::varnish::frontend::backends_in_etcd', {'default_value' => true}),
    String $fe_jemalloc_conf = lookup('profile::cache::varnish::frontend::fe_jemalloc_conf'),
    Array[String] $fe_extra_vcl = lookup('profile::cache::varnish::frontend::fe_extra_vcl'),
    Array[String] $runtime_params = lookup('profile::cache::varnish::frontend::runtime_params'),
    Profile::Cache::Sites $req_handling = lookup('cache::req_handling'),
    Profile::Cache::Sites $alternate_domains = lookup('cache::alternate_domains', {'default_value' => {}}),
    String $packages_component = lookup('profile::cache::varnish::frontend::packages_component', {'default_value' => 'component/varnish6'}),
    Array[String] $separate_vcl = lookup('profile::cache::varnish::separate_vcl', {'default_value' =>  []}),
    Integer $fe_transient_gb = lookup('profile::cache::varnish::frontend::transient_gb', {'default_value' => 0}),
    Boolean $has_lvs = lookup('has_lvs', {'default_value' => true}),
    Optional[Stdlib::Unixpath] $listen_uds = lookup('profile::cache::varnish::frontend::listen_uds', {'default_value' => undef}),
    Optional[Stdlib::Fqdn] $single_backend_experiment = lookup('cache::single_backend_fqdn', {'default_value' => undef}),
    Boolean $proxy_on_uds = lookup('profile::cache::varnish::frontend::proxy_on_uds', {'default_value' => false}),
    String $uds_owner = lookup('profile::cache::varnish::frontend::uds_owner', {'default_value' => 'root'}),
    String $uds_group = lookup('profile::cache::varnish::frontend::uds_group', {'default_value' => 'root'}),
    Stdlib::Filemode $uds_mode = lookup('profile::cache::varnish::frontend::uds_mode', {'default_value' => '700'}),
) {
    require ::profile::cache::base
    $wikimedia_nets = $profile::cache::base::wikimedia_nets
    $wikimedia_trust = $profile::cache::base::wikimedia_trust

    if $has_lvs {
        require ::profile::lvs::realserver
    }

    $packages = [
        'varnish',
        'varnish-modules',
        'libvmod-netmapper',
        'libvmod-re2',
    ]

    if $packages_component == 'main' {
        package { $packages:
            ensure => installed,
            before => Mount['/var/lib/varnish'],
        }
    } else {
        apt::package_from_component { 'varnish':
            component => $packages_component,
            packages  => $packages,
            before    => Mount['/var/lib/varnish'],
            priority  => 1002, # Take precedence over main
        }
    }

    # Mount /var/lib/varnish as tmpfs to avoid Linux flushing mlocked
    # shm memory to disk
    mount { '/var/lib/varnish':
        ensure  => mounted,
        device  => 'tmpfs',
        fstype  => 'tmpfs',
        options => 'noatime,defaults,size=512M',
        pass    => 0,
        dump    => 0,
    }

    # Frontend memory cache sizing
    $mem_gb = $::memorysize_mb / 1024.0
    if ($mem_gb < 90.0) {
        # virtuals, test hosts, etc...
        $fe_mem_gb = 1
    } else {
        # Removing a constant factor before scaling helps with
        # low-memory hosts, as they need more relative space to
        # handle all the non-cache basics.
        $fe_mem_gb = ceiling(0.7 * ($mem_gb - 100.0))
    }

    $vcl_config = $fe_vcl_config + {
        req_handling         => $req_handling,
        alternate_domains    => $alternate_domains,
        fe_mem_gb            => $fe_mem_gb,
    }

    # VCL files common to all instances
    class { 'varnish::common::vcl':
        vcl_config => $vcl_config,
    }

    $separate_vcl_frontend = $separate_vcl.map |$vcl| { "${vcl}-frontend" }

    # Experiment with single backend CDN nodes T288106
    if $single_backend_experiment {
        if $::fqdn == $single_backend_experiment {
            $backend_caches = [ $::fqdn ]
            $etcd_backends = false
        } else {
            $backend_caches = $cache_nodes[$cache_cluster][$::site] - $single_backend_experiment
            $etcd_backends = $backends_in_etcd
        }
        $confd_experiment_fqdn = $single_backend_experiment
    } else {
        $backend_caches = $cache_nodes[$cache_cluster][$::site]
        $etcd_backends = $backends_in_etcd
        $confd_experiment_fqdn = ''
    }

    if $etcd_backends {
        # Backend caches used by this Frontend from Etcd
        $reload_vcl_opts = varnish::reload_vcl_opts($vcl_config['varnish_probe_ms'],
            $separate_vcl_frontend, 'frontend', "${cache_cluster}-frontend")

        $keyspaces = [ "${conftool_prefix}/pools/${::site}/cache_${cache_cluster}/ats-be" ]

        confd::file { '/etc/varnish/directors.frontend.vcl':
            ensure     => present,
            watch_keys => $keyspaces,
            content    => template('profile/cache/varnish-frontend.directors.vcl.tpl.erb'),
            reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
            before     => Service['varnish-frontend'],
        }
    }

    # Transient storage limits T164768
    if $fe_transient_gb > 0 {
        $fe_transient_storage = "-s Transient=malloc,${fe_transient_gb}G"
    } else {
        $fe_transient_storage = ''
    }

    # Raise maximum number of memory map areas per process from 65530 to
    # $vm_max_map_count. See https://www.kernel.org/doc/Documentation/sysctl/vm.txt.
    # Varnish frontend crashes with "Error in munmap(): Cannot allocate
    # memory" are likely due to the varnish child process reaching this limit.
    # https://phabricator.wikimedia.org/T242417
    $vm_max_map_count = 262120

    sysctl::parameters { 'maximum map count':
        values => {
            'vm.max_map_count' => $vm_max_map_count,
        }
    }

    class { 'prometheus::node_varnishd_mmap_count':
        service => 'varnish-frontend.service',
    }

    monitoring::check_prometheus { 'varnishd-mmap-count':
        description     => 'Varnish number of memory map areas',
        query           => "scalar(varnishd_mmap_count{instance=\"${::hostname}:9100\"})",
        method          => 'gt',
        warning         => $vm_max_map_count - 5000,
        critical        => $vm_max_map_count - 1000,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/cache-host-drilldown?fullscreen&orgId=1&panelId=76&var-site=${::site} prometheus/ops&var-instance=${::hostname}"],
    }

    # Monitor number of varnish file descriptors. Initially added to track
    # T243634 but generally useful.
    prometheus::node_file_count {'track vcache fds':
        paths   => [ '/proc/$(pgrep -u vcache)/fd' ],
        outfile => '/var/lib/prometheus/node.d/vcache_fds.prom',
        metric  => 'node_varnish_filedescriptors_total',
    }

    # lint:ignore:arrow_alignment
    varnish::instance { "${cache_cluster}-frontend":
        instance_name      => 'frontend',
        vcl                => "${cache_cluster}-frontend",
        separate_vcl       => $separate_vcl_frontend,
        extra_vcl          => $fe_extra_vcl,
        ports              => [ '80', '3120', '3121', '3122', '3123', '3124', '3125', '3126', '3127' ],
        admin_port         => 6082,
        runtime_params     => join(prefix($runtime_params, '-p '), ' '),
        storage            => "-s malloc,${fe_mem_gb}G ${fe_transient_storage}",
        jemalloc_conf      => $fe_jemalloc_conf,
        backend_caches     => $backend_caches,
        backend_options    => $fe_cache_be_opts,
        backends_in_etcd   => $etcd_backends,
        vcl_config         => $vcl_config,
        wikimedia_nets     => $wikimedia_nets,
        wikimedia_trust    => $wikimedia_trust,
        listen_uds         => $listen_uds,
        proxy_on_uds       => $proxy_on_uds,
        uds_owner          => $uds_owner,
        uds_group          => $uds_group,
        uds_mode           => $uds_mode,
    }
    # lint:endignore
}
