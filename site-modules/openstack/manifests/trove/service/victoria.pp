class openstack::trove::service::victoria(
    Array[Stdlib::Fqdn] $openstack_controllers,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $ldap_user_pass,
    String              $keystone_admin_uri,
    String              $keystone_internal_uri,
    String              $region,
    Stdlib::Port        $api_bind_port,
    String              $rabbit_user,
    String              $rabbit_pass,
    String              $trove_guest_rabbit_user,
    String              $trove_guest_rabbit_pass,
    String              $trove_service_user_pass,
    String              $trove_service_project,
    String              $trove_service_user,
    String              $trove_quay_user,
    String              $trove_quay_pass,
    String              $designate_internal_uri,
    String              $trove_dns_zone,
    String              $trove_dns_zone_id,
) {
    require "openstack::serverpackages::victoria::${::lsbdistcodename}"

    package { ['python3-trove', 'trove-common', 'trove-api', 'trove-taskmanager', 'trove-conductor']:
        ensure => 'present',
    }

    file {
        '/etc/trove/trove.conf':
            content   => template('openstack/victoria/trove/trove.conf.erb'),
            owner     => 'trove',
            group     => 'trove',
            mode      => '0440',
            show_diff => false,
            notify    => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require   => Package['trove-api'];
        '/etc/trove/trove-guestagent.conf':
            content   => template('openstack/victoria/trove/trove-guestagent.conf.erb'),
            owner     => 'trove',
            group     => 'trove',
            mode      => '0440',
            show_diff => false,
            notify    => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require   => Package['trove-api'];
        '/etc/trove/policy.yaml':
            source  => 'puppet:///modules/openstack/victoria/trove/policy.yaml',
            owner   => 'trove',
            group   => 'trove',
            mode    => '0644',
            notify  => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require => Package['trove-api'];
        '/etc/trove/api-paste.ini':
            source  => 'puppet:///modules/openstack/victoria/trove/api-paste.ini',
            owner   => 'trove',
            group   => 'trove',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
        '/usr/lib/python3/dist-packages/trove/taskmanager/models.py':
            source  => 'puppet:///modules/openstack/victoria/trove/hacks/taskmanager/models.py',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
        '/usr/lib/python3/dist-packages/trove/instance/models.py':
            source  => 'puppet:///modules/openstack/victoria/trove/hacks/instance/models.py',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
    }
}
