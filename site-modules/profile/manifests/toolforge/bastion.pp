# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion(
    Stdlib::Host $active_cronrunner = lookup('profile::toolforge::active_cronrunner'),
){
    # Son of Grid Engine Configuration
    # admin_host???
    include profile::toolforge::shell_environ
    include profile::toolforge::grid::exec_environ
    include profile::toolforge::k8s::client

    if debian::codename::eq('buster') {
        include profile::toolforge::jobs_framework_cli
    }

    file { '/etc/toollabs-cronhost':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $active_cronrunner,
    }
    file { '/usr/local/bin/crontab':
        ensure  => 'link',
        target  => '/usr/bin/oge-crontab',
        require => Package['misctools'],
    }

    file { '/usr/local/sbin/qstat-full':
        ensure => absent,
    }

    file { '/usr/local/bin/qstat-full':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/qstat-full',
    }

    file { '/bin/disabledtoolshell':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/disabledtoolshell',
    }

    # TODO: once bastions from the eqiad.wmflabs generation are gone, return to using $facts['fqdn']
    file { "${profile::toolforge::grid::base::store}/submithost-${facts['hostname']}.${::labsproject}.eqiad1.wikimedia.cloud":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$profile::toolforge::grid::base::store],
        content => "${::ipaddress}\n",
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::labsproject}-bastion-banner.sh",
    }

    # Display tips.
    file { '/etc/profile.d/motd-tips.sh':
        ensure  => absent,
    }

    package { 'mosh':
        ensure => present,
    }

    # General SSH Use Configuration
    file { '/etc/ssh/ssh_config':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/submithost-ssh_config',
    }
}
