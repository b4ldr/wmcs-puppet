# Prometheus Traffic Server metrics exporter.

# === Parameters
#
# [*instance_name*]
#  Traffic server instance name (default: backend)
#
# [*$endpoint*]
#  The stats_over_http Traffic Server URL
#
# [*$listen_port*]
#  The TCP port to listen on
#
# [*$verify_ssl_certificate*]
#  Boolean signaling if verification of the SSL certificate used by Traffic server should be performed
#  (default: enabled (true))

define prometheus::trafficserver_exporter (
    String $instance_name = 'backend',
    Stdlib::HTTPUrl $endpoint  = 'http://127.0.0.1/_stats',
    Stdlib::Port::User $listen_port = 9122,
    Boolean $verify_ssl_certificate = true,
) {
    ensure_packages('prometheus-trafficserver-exporter')

    $service_name = "prometheus-trafficserver-${instance_name}-exporter"
    $metrics_file = '/etc/prometheus-trafficserver-exporter-metrics.yaml'
    if !defined(File[$metrics_file]) {
        file { $metrics_file:
            ensure => present,
            source => 'puppet:///modules/prometheus/trafficserver_exporter/metrics.yaml',
        }
    }

    systemd::service { $service_name:
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-trafficserver-exporter@'),
    }

    File[$metrics_file] ~> Service[$service_name]

    monitoring::service { "trafficserver_${instance_name}_exporter_check_http":
        description   => "Ensure traffic_exporter for the ${instance_name} instance binds on port ${listen_port} and responds to HTTP requests",
        check_command => "check_http_port_url!${listen_port}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    profile::auto_restarts::service { $service_name: }
}
