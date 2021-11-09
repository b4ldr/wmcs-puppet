class role::mariadb::core {
    system::role { 'mariadb::core':
        description => 'Core DB Server',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::role::mariadb::ferm
    include ::profile::mariadb::core
}
