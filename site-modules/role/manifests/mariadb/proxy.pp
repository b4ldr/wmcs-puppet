# generic config for a database proxy using haproxy
class role::mariadb::proxy {
    include ::profile::base::production

    system::role { 'mariadb::proxy':
        description => 'DB Proxy',
    }

    include ::profile::mariadb::proxy
    include ::profile::mariadb::client
}
