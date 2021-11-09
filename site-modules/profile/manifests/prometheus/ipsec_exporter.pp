class profile::prometheus::ipsec_exporter(
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    class { '::prometheus::ipsec_exporter': }

    ferm::service { 'prometheus_ipsec_exporter':
        proto  => 'tcp',
        port   => '9536',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }

}
