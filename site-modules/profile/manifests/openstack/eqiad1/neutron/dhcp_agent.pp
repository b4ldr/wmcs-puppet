class profile::openstack::eqiad1::neutron::dhcp_agent(
    $version = lookup('profile::openstack::eqiad1::version'),
    $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    $report_interval = lookup('profile::openstack::eqiad1::neutron::report_interval'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version         => $version,
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
