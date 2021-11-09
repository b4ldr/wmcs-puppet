# this class is currently unused. Perhaps worth reallocating code
# to profile::openstack::codfw1dev::db
class profile::openstack::base::keystone::db(
    $labs_hosts_range = lookup('profile::openstack::base::labs_hosts_range'),
    $labs_hosts_range_v6 = lookup('profile::openstack::base::labs_hosts_range_v6'),
    $puppetmaster_hostname = lookup('profile::openstack::base::puppetmaster_hostname'),
    $designate_host = lookup('profile::openstack::base::designate_host'),
    $osm_host = lookup('profile::openstack::base::osm_host'),
    Array[String] $mysql_root_clients = lookup('mysql_root_clients', {'default_value' => []}),
){

    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients_str})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients_str})",
    }

    ferm::rule{'mysql_nova':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range} proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_nova_v6':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range_v6} proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_designate':
        ensure => 'present',
        rule   => "saddr (@resolve((${designate_host})) @resolve((${designate_host}), AAAA)) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_puppetmaster':
        ensure => 'present',
        rule   => "saddr (@resolve(${puppetmaster_hostname}) @resolve(${puppetmaster_hostname}, AAAA)) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_wikitech':
        ensure => 'present',
        rule   => "saddr (@resolve(${osm_host}) @resolve(${osm_host}, AAAA)) proto tcp dport (3306) ACCEPT;",
    }
}
