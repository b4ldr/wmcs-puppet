class profile::openstack::eqiad1::wikitech::monitor(
    $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
    ) {

    class {'::profile::openstack::base::wikitech::monitor':
        osm_host => $osm_host,
    }
}
