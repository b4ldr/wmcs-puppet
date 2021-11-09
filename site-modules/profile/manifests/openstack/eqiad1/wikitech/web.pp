class profile::openstack::eqiad1::wikitech::web(
    $osm_host = lookup('profile::openstack::eqiad1::wikitech::web::osm_host'),
    $webserver_hostname_aliases = lookup('profile::openstack::eqiad1::wikitech::webserver_hostname_aliases'),
    $wikidb = lookup('profile::openstack::eqiad1::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = lookup('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    ) {

    class {'profile::openstack::base::wikitech::web':
        osm_host                           => $osm_host,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    class {'::openstack::wikitech::wikitech_static_sync': }
}
