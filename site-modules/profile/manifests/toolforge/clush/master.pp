# profile::toolforge::clush::master - configure clustershell master
#
# * $observer_pass - Password used to connect to OpenStack and retrieve
#                    list of instances

class profile::toolforge::clush::master(
    String $observer_pass = lookup('profile::openstack::eqiad1::observer_password'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages::vms

    class { '::clush::master':
        username => 'clushuser',
    }

    ensure_packages('python3-yaml')

    file { '/usr/local/sbin/tools-clush-generator':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/tools-clush-generator.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/tools-clush-interpreter':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/tools-clush-interpreter.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/clush':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/clush',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::timer::job { 'toolforge_clush_update':
        ensure                    => present,
        description               => 'Update list of Toolforge servers for clush',
        command                   => "/usr/local/sbin/tools-clush-generator /etc/clustershell/tools.yaml --observer-pass ${observer_pass}",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00:00', # hourly
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => 'root',
    }

    $groups_config = {
        'Main' => {
            'default' => 'Tools',
        },
        'Tools' => {
            'map' => '/usr/local/sbin/tools-clush-interpreter --hostgroups /etc/clustershell/tools.yaml map $GROUP',
            'list' => '/usr/local/sbin/tools-clush-interpreter --hostgroups /etc/clustershell/tools.yaml list',
        },
    }

    file { '/etc/clustershell/groups.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ini($groups_config),
    }

    # Usage: `clush --hostfile /etc/clustershell/toolforge_canary_list.txt 'cmd'`
    file { '/etc/clustershell/toolforge_canary_list.txt':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/toolforge_canary_list.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
