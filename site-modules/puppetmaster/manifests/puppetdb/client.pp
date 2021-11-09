# == Class puppetmaster::puppetdb::client
# Configures a puppetmaster to work as a puppetdb client
class puppetmaster::puppetdb::client(
    Array[Stdlib::Host] $hosts,
    Stdlib::Port        $port              = 443,
    Boolean             $command_broadcast = false,
) {
    $puppetdb_conf_template    = 'puppetmaster/puppetdb4.conf.erb'

    ensure_packages('puppet-terminus-puppetdb')

    file { '/etc/puppet':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/etc/puppet/puppetdb.conf':
        ensure  => present,
        content => template($puppetdb_conf_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/puppet/routes.yaml':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/puppetmaster/routes.yaml',
    }

    if defined(Service['apache2']) {
        File['/etc/puppet/routes.yaml'] -> Service['apache2']
    }

    # Absence of this directory causes the puppetmaster to spit out
    # 'Removing mount "facts": /var/lib/puppet/facts does not exist or is not a directory'
    # and catalog compilation to fail with https://tickets.puppetlabs.com/browse/PDB-949
    file { '/var/lib/puppet/facts':
        ensure => directory,
    }
}
