define swift::stats::stats_container (
    $account_name,
    $container_set,
    $statsd_prefix,
    Wmflib::Ensure $ensure = present,
    $statsd_host = 'localhost',
    $statsd_port = 9125,
) {
    $account_file = "/etc/swift/account_${account_name}.env"

    cron { "swift-container-stats_${title}":
        ensure  => $ensure,
        command => ". ${account_file} && /usr/local/bin/swift-container-stats --prefix ${statsd_prefix} --statsd-host ${statsd_host} --statsd-port ${statsd_port} --ignore-unknown --container-set ${container_set} 1>/dev/null",
        user    => 'root',
        hour    => '*',
        minute  => '*/10',
        require => [File[$account_file],
                    File['/usr/local/bin/swift-container-stats']],
    }
}
