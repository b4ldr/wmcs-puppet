class profile::openstack::codfw1dev::pdns::recursor::service(
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $observer_password = lookup('profile::openstack::codfw1dev::observer_password'),
    Array[Stdlib::Fqdn] $pdns_hosts = lookup('profile::openstack::codfw1dev::pdns::hosts'),
    Stdlib::Fqdn $recursor_service_name = lookup('profile::openstack::codfw1dev::pdns::recursor_service_name'),
    $tld = lookup('profile::openstack::codfw1dev::pdns::tld'),
    $legacy_tld = lookup('profile::openstack::codfw1dev::pdns::legacy_tld'),
    $private_reverse_zones = lookup('profile::openstack::codfw1dev::pdns::private_reverse_zones'),
    $aliaser_extra_records = lookup('profile::openstack::codfw1dev::pdns::recursor_aliaser_extra_records'),
    Array[Stdlib::IP::Address] $extra_allow_from = lookup('profile::openstack::codfw1dev::pdns::extra_allow_from', {default_value => []}),
    Array[Stdlib::Fqdn]        $controllers      = lookup('profile::openstack::codfw1dev::openstack_controllers',  {default_value => []}),
    ) {

    # This iterates on $hosts and returns the entry in $hosts with the same
    #  ipv4 as $::fqdn
    $service_pdns_host = $pdns_hosts.reduce(false) |$memo, $service_host_fqdn| {
        if (ipresolve($::fqdn,4) == ipresolve($service_host_fqdn,4)) {
            $rval = $service_host_fqdn
        } else {
            $rval = $memo
        }
        $rval
    }

    class {'::profile::openstack::base::pdns::recursor::service':
        keystone_api_fqdn     => $keystone_api_fqdn,
        observer_password     => $observer_password,
        pdns_host             => $service_pdns_host,
        pdns_recursor         => $recursor_service_name,
        tld                   => $tld,
        legacy_tld            => $legacy_tld,
        private_reverse_zones => $private_reverse_zones,
        aliaser_extra_records => $aliaser_extra_records,
        extra_allow_from      => $extra_allow_from,
        controllers           => $controllers,
    }

    class{'::profile::openstack::base::pdns::recursor::monitor::rec_control':}
}
