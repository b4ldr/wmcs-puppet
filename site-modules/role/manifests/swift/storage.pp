class role::swift::storage {

    system::role { 'swift::storage':
        description => 'swift storage brick',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::swift::storage
    include ::toil::systemd_scope_cleanup

    class { '::profile::prometheus::statsd_exporter':
        relay_address => '',
    }

    include ::profile::swift::storage::expirer

    include ::profile::swift::performance
}
