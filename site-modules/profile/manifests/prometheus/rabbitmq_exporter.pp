class profile::prometheus::rabbitmq_exporter (
    Array[Stdlib::Host] $prometheus_nodes        = lookup('prometheus_nodes'),
    String              $rabbit_monitor_username = lookup('profile::prometheus::rabbit_monitor_user'),
    String              $rabbit_monitor_password = lookup('profile::prometheus::rabbit_monitor_pass'),
){

    $rabbit_host = 'localhost:15672'

    file { '/etc/prometheus/':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/prometheus/rabbitmq-exporter.yaml':
        ensure  => 'present',
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0440',
        content => template('profile/prometheus/rabbitmq-exporter.conf.erb'),
        require => File['/etc/prometheus/'],
    }

    ensure_packages('prometheus-rabbitmq-exporter')

    service { 'prometheus-rabbitmq-exporter':
        ensure  => running,
        require => File['/etc/prometheus/rabbitmq-exporter.yaml'],
    }

    profile::auto_restarts::service { 'prometheus-rabbitmq-exporter': }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $prometheus_ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    ferm::service { 'prometheus-rabbitmq-exporter':
        proto  => 'tcp',
        port   => '9195',
        srange => $prometheus_ferm_srange,
    }
}
