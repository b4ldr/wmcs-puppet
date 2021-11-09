# Prometheus Haproxy metrics exporter.

# === Parameters
#
# [*$endpoint*]
#  The stats_over_http Haproxy URL
#
# [*$listen_port*]
#  The TCP port to listen on

class prometheus::haproxy_exporter (
    Stdlib::HTTPUrl $endpoint  = 'http://localhost:9100/?stats;csv',
    Stdlib::Port::User $listen_port = 9901,
) {
    ensure_packages('prometheus-haproxy-exporter')

    $exec_binary = $::lsbdistcodename ? {
        buster  => '/usr/bin/prometheus-haproxy-exporter',
        stretch => '/usr/bin/haproxy_exporter',
    }

    systemd::service { 'prometheus-haproxy-exporter':
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-haproxy-exporter'),
    }

    profile::auto_restarts::service { 'prometheus-haproxy-exporter': }
}
