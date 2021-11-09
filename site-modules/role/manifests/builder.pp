class role::builder {

    include profile::base::production
    include profile::base::firewall
    include profile::package_builder
    include profile::docker::storage::loopback
    include profile::docker::engine
    include profile::docker::builder
    include profile::docker::ferm
    include profile::docker::reporter
    include profile::systemtap::devserver

    system::role { 'builder':
        description => 'Docker images builder',
    }
}
