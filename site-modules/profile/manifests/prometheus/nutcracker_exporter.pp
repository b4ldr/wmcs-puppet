class profile::prometheus::nutcracker_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ensure_packages('prometheus-nutcracker-exporter')

    service { 'prometheus-nutcracker-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-nutcracker-exporter':
        proto  => 'tcp',
        port   => '9191',
        srange => $ferm_srange,
    }

    profile::auto_restarts::service { 'prometheus-nutcracker-exporter': }
}
