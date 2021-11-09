class profile::prometheus::etherpad_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ensure_packages('prometheus-etherpad-exporter')

    service { 'prometheus-etherpad-exporter':
        ensure  => running,
    }

    profile::auto_restarts::service { 'prometheus-etherpad-exporter': }

    ferm::service { 'prometheus-etherpad-exporter':
        proto  => 'tcp',
        port   => '9198',
        srange => $ferm_srange,
    }
}
