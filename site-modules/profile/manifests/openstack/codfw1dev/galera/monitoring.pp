class profile::openstack::codfw1dev::galera::monitoring(
    Integer             $nodecount             = lookup('profile::openstack::codfw1dev::galera::node_count'),
    Stdlib::Port        $port                  = lookup('profile::openstack::codfw1dev::galera::listen_port'),
    String              $test_username         = lookup('profile::openstack::codfw1dev::galera::test_username'),
    String              $test_password         = lookup('profile::openstack::codfw1dev::galera::test_password'),
){
    # Bypass haproxy and check the backend mysqld port directly. We want to notice
    #  degraded service even if the haproxy'd front end is holding up.
    monitoring::service { 'galera_cluster':
        description   => 'WMCS Galera Cluster',
        check_command => "check_galera_node!${nodecount}!${port}!${test_username}!${test_password}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        contact_group => 'wmcs-team,admins',
    }

    monitoring::service { 'galera_db':
        description   => 'WMCS Galera Database',
        check_command => "check_galera_db!${port}!${test_username}!${test_password}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        contact_group => 'wmcs-team,admins',
    }
}
