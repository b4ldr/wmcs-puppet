class openstack::neutron::service::ussuri(
    Stdlib::Port $bind_port,
    Boolean $active,
    ) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ussuri::${::lsbdistcodename}"

    service {'neutron-api':
        ensure    => $active,
        require   => Package['neutron-server', 'neutron-api'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.yaml'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }

    package { 'neutron-server':
        ensure => 'present',
    }
    package { 'neutron-api':
        ensure => 'present',
    }

    # Our 'neutron-server' script is just the packaged neutron-api script
    #  renamed and with the port changed.
    file {
        '/etc/init.d/neutron-api':
            content => template('openstack/ussuri/neutron/neutron-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['neutron-api'],
            require => Package['neutron-server', 'neutron-api'];
        '/etc/init.d/neutron-server':
            ensure => absent;
        '/etc/neutron/neutron-api-uwsgi.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/ussuri/neutron/neutron-api-uwsgi.ini',
            notify  => Service['neutron-api'],
            require => Package['neutron-api'];
        '/etc/neutron/api-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/ussuri/neutron/api-paste.ini',
            notify  => Service['neutron-api'],
            require => Package['neutron-api'];
        '/var/run/neutron/':
            ensure => directory,
            owner  => 'neutron',
            group  => 'neutron',
            mode   => '0755';

    }
}
