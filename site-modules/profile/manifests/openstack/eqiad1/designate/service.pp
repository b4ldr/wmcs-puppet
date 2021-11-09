class profile::openstack::eqiad1::designate::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::eqiad1::puppetmaster_hostname'),
    $db_pass = lookup('profile::openstack::eqiad1::designate::db_pass'),
    $db_host = lookup('profile::openstack::eqiad1::designate::db_host'),
    $domain_id_internal_forward = lookup('profile::openstack::eqiad1::designate::domain_id_internal_forward'),
    $domain_id_internal_forward_legacy = lookup('profile::openstack::eqiad1::designate::domain_id_internal_forward_legacy'),
    $domain_id_internal_reverse = lookup('profile::openstack::eqiad1::designate::domain_id_internal_reverse'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::eqiad1::pdns::api_key'),
    $db_admin_pass = lookup('profile::openstack::eqiad1::designate::db_admin_pass'),
    Array[Stdlib::Fqdn] $pdns_hosts = lookup('profile::openstack::eqiad1::pdns::hosts'),
    $rabbit_pass = lookup('profile::openstack::eqiad1::nova::rabbit_pass'),
    $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
    $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
    $region = lookup('profile::openstack::eqiad1::region'),
    $puppet_git_repo_name = lookup('profile::openstack::eqiad1::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = lookup('profile::openstack::eqiad1::horizon::puppet_git_repo_user'),
    Integer $mcrouter_port = lookup('profile::openstack::eqiad1::designate::mcrouter_port'),
) {

    require ::profile::openstack::eqiad1::clientpackages
    class{'::profile::openstack::base::designate::service':
        version                           => $version,
        designate_hosts                   => $designate_hosts,
        keystone_api_fqdn                 => $keystone_api_fqdn,
        db_pass                           => $db_pass,
        db_host                           => $db_host,
        domain_id_internal_forward        => $domain_id_internal_forward,
        domain_id_internal_forward_legacy => $domain_id_internal_forward_legacy,
        domain_id_internal_reverse        => $domain_id_internal_reverse,
        puppetmaster_hostname             => $puppetmaster_hostname,
        openstack_controllers             => $openstack_controllers,
        ldap_user_pass                    => $ldap_user_pass,
        pdns_api_key                      => $pdns_api_key,
        db_admin_pass                     => $db_admin_pass,
        pdns_hosts                        => $pdns_hosts,
        rabbit_pass                       => $rabbit_pass,
        osm_host                          => $osm_host,
        labweb_hosts                      => $labweb_hosts,
        region                            => $region,
        puppet_git_repo_name              => $puppet_git_repo_name,
        puppet_git_repo_user              => $puppet_git_repo_user,
        mcrouter_port                     => $mcrouter_port,
    }

    class {'::openstack::designate::monitor':
        active         => true,
        contact_groups => 'wmcs-team',
    }
}
