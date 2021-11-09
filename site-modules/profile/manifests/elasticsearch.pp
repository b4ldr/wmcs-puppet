#
# This class configures elasticsearch
#
# == Parameters:
# - $dc_settings: data center specific overrides for ::elasticsearch::instance
# - $common_settings: global overrides for ::elasticsearch::instance
# - $logstash_host: Host to send logs to
# - $logstash_gelf_port: Tcp port on $logstash_host to send gelf formatted logs to.
# - $logstash_logback_port: Tcp port on localhost to send structured logs to.
# - $logstash_transport: Transport mechanism for logs.
# - $rack: Rack server is in. Used for allocation awareness.
# - $row: Row server is in. Used for allocation awareness.
# - $version: version of the package to install
# - $config_version: configure for this versionof elastic. This is independant from $version as during the transition
#                    ES5 -> ES6, we need to deploy the new package before applying the configuration.
#                    TODO: remove this configuration option once all instances have been migrated to ES6.
# - $java_home: optionally specify the JAVA_HOME path in the elasticsearch systemd unit.
#               note: used only with ES7.
#
#
class profile::elasticsearch(
    Hash[String, Elasticsearch::InstanceParams] $instances = lookup('profile::elasticsearch::instances'),
    Elasticsearch::InstanceParams $dc_settings = lookup('profile::elasticsearch::dc_settings'),
    Elasticsearch::InstanceParams $common_settings = lookup('profile::elasticsearch::common_settings'),
    Stdlib::AbsolutePath $base_data_dir = lookup('profile::elasticsearch::base_data_dir'),
    String $logstash_host = lookup('logstash_host'),
    Stdlib::Port $logstash_gelf_port = lookup('logstash_gelf_port'),
    Stdlib::Port $logstash_logback_port = lookup('logstash_logback_port'),
    Enum['Gelf', 'syslog'] $logstash_transport = lookup('profile::elasticsearch::logstash_transport', {'default_value' => 'Gelf'}),
    String $rack = lookup('profile::elasticsearch::rack'),
    String $row = lookup('profile::elasticsearch::row'),
    Enum['5.5', '5.6', '6.5', '7.4', '7.8', '7.9', '7.10'] $version = lookup('profile::elasticsearch::version', {'default_value' => '5.5'}),
    Enum['5', '6', '7'] $config_version = lookup('profile::elasticsearch::config_version', {'default_value' => '5'}),
    Optional[String] $java_home = lookup('profile::elasticsearch::java_home', { 'default_value' => undef }),
) {

    require ::profile::java

    # Rather than asking hiera to magically merge these settings for us, we
    # explicitly take two sets of defaults for global defaults and per-dc
    # defaults. Per cluster overrides are then provided in $instances.
    $settings = $common_settings + $dc_settings

    # Sane defaults to simplify single instance configuration
    $defaults_for_single_instance = {
        http_port          => 9200,
        transport_tcp_port => 9300,
    }

    # Resolve instance configuration here, rather than in the elasticsearch
    # define, so we have access to final configuration, such as http ports,
    # for configuring firewalls and such.
    # Also accessed from profile::elasticsearch::* for firewalls, proxies, etc.
    $configured_instances = empty($instances) ? {
        true    => {
            'default' => $defaults_for_single_instance + $settings,
        },
        default => $instances.reduce({}) |$agg, $kv_pair| {
            $instance_title = $kv_pair[0]
            $instance_params = $kv_pair[1]
            $final_params = $settings + $instance_params
            $agg + [$instance_title, $final_params]
        }
    }

    # Get all unique elastic nodes across all instances.
    # This is needed to set ferm rules for cross cluster communication
    $all_elastic_nodes = unique($configured_instances.reduce([]) |$result, $instance_params| {
        $result + $instance_params[1]['cluster_hosts']
    })

    # filter out instances that should not be deployed on this node
    # this is used for the cirrus clusters, where multiple sub clusters are defined
    # on a subset of all nodes.
    #
    # note in filter |$instance| below, $instance is an array [ key, value ]
    # see https://puppet.com/docs/puppet/5.5/function.html#filter for details
    $filtered_instances = $configured_instances.filter |$instance| { $facts['fqdn'] in $instance[1]['cluster_hosts'] }

    # Accessed from profile::elasticsearch::* for firewalls, proxies, etc.
    $filtered_instances.each |$instance_title, $instance_params| {
        $transport_tcp_port = pick_default($instance_params['transport_tcp_port'], 9300)
        $elastic_nodes_ferm = join(pick_default($all_elastic_nodes, [$::fqdn]), ' ')

        ferm::service { "elastic-inter-node-${transport_tcp_port}":
            proto   => 'tcp',
            port    => $transport_tcp_port,
            notrack => true,
            srange  => "@resolve((${elastic_nodes_ferm}))",
        }

        # Let deploy this check per node/ per cluster. see T231516
        icinga::monitor::elasticsearch::old_jvm_gc_checks { $instance_params['cluster_name']: }
    }

    $apt_component = $version ? {
        '5.5'  => 'elastic55',
        '5.6'  => 'elastic56',
        '6.5'  => 'elastic65',
        '7.4'  => 'elastic74',
        '7.8'  => 'elastic78',
        '7.9'  => 'elastic79',
        '7.10' => 'elastic710',
    }

    apt::repository { 'wikimedia-elastic':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "component/${apt_component} thirdparty/${apt_component}",
        before     => Class['::elasticsearch'],
    }

    apt::repository { 'wikimedia-curator':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/elasticsearch-curator5',
        before     => Class['::elasticsearch::curator'],
    }

    # Originally added as part of T265113 - userland util to interact with kernel EDAC drivers
    package { 'edac-utils':
        ensure => latest,
    }

    # ensure that apt is refreshed before installing elasticsearch
    Exec['apt-get update'] -> Class['::elasticsearch']

    # Install
    class { '::elasticsearch':
        version               => $config_version,
        instances             => $filtered_instances,
        base_data_dir         => $base_data_dir,
        logstash_host         => $logstash_host,
        logstash_gelf_port    => $logstash_gelf_port,
        logstash_logback_port => $logstash_logback_port,
        logstash_transport    => $logstash_transport,
        rack                  => $rack,
        row                   => $row,
        java_home             => $java_home,
    }
}
