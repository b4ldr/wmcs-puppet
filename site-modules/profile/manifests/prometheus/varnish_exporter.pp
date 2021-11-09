# == Class: profile::prometheus::varnish_exporter
#
# The profile sets up the prometheus exporter for varnish frontend on tcp/9331
#
# === Parameters
# [*nodes*] List of prometheus nodes
#

class profile::prometheus::varnish_exporter(
    Array[Stdlib::Host] $nodes = lookup('prometheus_nodes')
) {
    $prometheus_ferm_nodes = join($nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    prometheus::varnish_exporter{ 'frontend':
        instance       => 'frontend',
        listen_address => ':9331',
    }

    ferm::service { 'prometheus-varnish-exporter-frontend':
        proto  => 'tcp',
        port   => '9331',
        srange => $ferm_srange,
    }
}
