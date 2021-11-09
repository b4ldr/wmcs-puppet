# This profile sets up a grid shadow master in the Toolforge model.

class profile::toolforge::grid::shadow(
    Stdlib::Host $gridmaster = lookup('sonofgridengine::gridmaster'),
    Stdlib::Unixpath $geconf = lookup('profile::toolforge::grid::base::geconf'),
){

    include profile::openstack::eqiad1::clientpackages::vms
    include profile::openstack::eqiad1::observerenv
    include profile::toolforge::infrastructure

    file { '/var/spool/gridengine':
        ensure => link,
        target => "${geconf}/spool",
        force  => true,
    }

    class { '::sonofgridengine::shadow_master':
        gridmaster => $gridmaster,
        sgeroot    => $geconf,
    }

    file { '/usr/local/sbin/exec-manage':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/exec-manage',
    }
}
