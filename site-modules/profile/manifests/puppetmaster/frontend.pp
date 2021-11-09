# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::frontend(
    Hash                $config                  = lookup('profile::puppetmaster::frontend::config'),
    Boolean             $secure_private          = lookup('profile::puppetmaster::frontend::secure_private'),
    String              $web_hostname            = lookup('profile::puppetmaster::frontend::web_hostname'),
    Boolean             $prevent_cherrypicks     = lookup('profile::puppetmaster::frontend::prevent_cherrypicks'),
    Stdlib::Host        $ca_server               = lookup('puppet_ca_server'),
    Stdlib::Filesource  $ca_source               = lookup('puppet_ca_source'),
    Boolean             $manage_ca_file          = lookup('manage_puppet_ca_file'),
    Array[String]       $allow_from              = lookup('profile::puppetmaster::frontend::allow_from'),
    String              $extra_auth_rules        = lookup('profile::puppetmaster::frontend::extra_auth_rules'),
    Boolean             $monitor_signed_certs    = lookup('profile::puppetmaster::frontend::monitor_signed_certs'),
    Integer             $signed_certs_warning    = lookup('profile::puppetmaster::frontend::signed_certs_warning'),
    Integer             $signed_certs_critical   = lookup('profile::puppetmaster::frontend::signed_certs_critical'),
    Array[Stdlib::Host] $canary_hosts            = lookup('profile::puppetmaster::frontend::canary_hosts'),
    Hash[String, Puppetmaster::Backends] $servers          = lookup('puppetmaster::servers'),
    Hash[Stdlib::Host, Stdlib::Host]     $locale_servers   = lookup('puppetmaster::locale_servers'),
    Enum['chain', 'leaf', 'none'] $ssl_ca_revocation_check = lookup('profile::puppetmaster::frontend::ssl_ca_revocation_check'),
    Optional[String[1]] $mcrouter_ca_secret      = lookup('profile::puppetmaster::frontend::mcrouter_ca_secret',
                                                          {'default_value' => undef}),
) {
    ensure_packages('libapache2-mod-passenger')

    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }
    if $manage_ca_file {
        file{[$facts['puppet_config']['master']['localcacert'],
              "${facts['puppet_config']['master']['ssldir']}/ca/ca_crt.pem"]:
            ensure => file,
            owner  => 'puppet',
            group  => 'puppet',
            source => $ca_source,
        }
    }
    # Puppet frontends are git masters at least for their datacenter
    if $ca_server == $::fqdn {
        $ca = true
        $sync_ensure = 'absent'
    } else {
        $ca = false
        $sync_ensure = 'present'
    }

    if $ca {
        # Ensure cergen is present for managing TLS keys and
        # x509 certificates signed by the Puppet CA.
        class { 'cergen': }
        if $mcrouter_ca_secret {
            class { 'cergen::mcrouter_ca':
                ca_secret => $mcrouter_ca_secret,
            }
        }

        # Ship cassandra-ca-manager (precursor of cergen)
        class { 'cassandra::ca_manager': }

        # Ensure nagios can read the signed certs
        $signed_cert_path = "${facts['puppet_config']['master']['ssldir']}/ca/signed"
        file {$signed_cert_path:
            ensure  => directory,
            owner   => 'puppet',
            group   => 'puppet',
            mode    => '0644',
            recurse => true,
        }
        $monitor_ensure = ($monitor_signed_certs and $ca).bool2str('present', 'absent')
        file {'/usr/local/lib/nagios/plugins/nrpe_check_puppetca_expired_certs':
            ensure => $monitor_ensure,
            mode   => '0555',
            source => 'puppet:///modules/profile/puppetmaster/nrpe_check_puppetca_expired_certs.sh',
        }
        nrpe::monitor_service {'puppetca_expired_certs':
            ensure         => $monitor_ensure,
            description    => 'Puppet CA expired certs',
            check_interval => 60,  # minutes
            timeout        => 60,  # seconds
            nrpe_command   => "/usr/local/lib/nagios/plugins/nrpe_check_puppetca_expired_certs ${signed_cert_path} ${signed_certs_warning} ${signed_certs_critical}",
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Puppet#Renew_agent_certificate',
        }
    }

    class { 'httpd':
        remove_default_ports => true,
        modules              => ['proxy', 'proxy_http', 'proxy_balancer',
                                'passenger', 'rewrite', 'lbmethod_byrequests'],
    }

    class { 'puppetmaster::ca_server':
        master => $ca_server
    }

    $common_config = {
        'ca'              => $ca,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }

    $base_config = merge($config, $common_config)

    class { 'profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { 'puppetmaster':
        bind_address        => '*',
        server_type         => 'frontend',
        is_git_master       => true,
        config              => $profile::puppetmaster::common::config,
        secure_private      => $secure_private,
        prevent_cherrypicks => $prevent_cherrypicks,
        allow_from          => $allow_from,
        extra_auth_rules    => $extra_auth_rules,
        ca_server           => $ca_server,
        ssl_verify_depth    => $profile::puppetmaster::common::ssl_verify_depth,
        servers             => $servers,
    }

    $workers = $servers[$facts['fqdn']]
    $locale_server = $locale_servers[$facts['fqdn']]
    # Main site to respond to
    puppetmaster::web_frontend { $web_hostname:
        master                  => $ca_server,
        workers                 => $workers,
        locale_server           => $locale_server,
        bind_address            => $::puppetmaster::bind_address,
        priority                => 40,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
        canary_hosts            => $canary_hosts,
        ssl_verify_depth        => $profile::puppetmaster::common::ssl_verify_depth,
    }

    # On all the puppetmasters, we should respond
    # to the FQDN too, in case we point them explicitly
    puppetmaster::web_frontend { $::fqdn:
        master                  => $ca_server,
        workers                 => $workers,
        locale_server           => $locale_server,
        bind_address            => $::puppetmaster::bind_address,
        priority                => 50,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
        canary_hosts            => $canary_hosts,
        ssl_verify_depth        => $profile::puppetmaster::common::ssl_verify_depth,
    }

    # Run the rsync servers on all puppetmaster frontends, and activate
    # timer jobs syncing from the master
    class { 'puppetmaster::rsync':
        server      => $ca_server,
        sync_ensure => $sync_ensure,
        frontends   => keys($servers),
    }

    ferm::service { 'puppetmaster-frontend':
        proto => 'tcp',
        port  => 8140,
    }

    $puppetmaster_frontend_ferm = join(keys($servers), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }

    ferm::service { 'rsync_puppet_frontends':
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
}
