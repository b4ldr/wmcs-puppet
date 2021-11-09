# Class: profile::wmcs::nfs::test
#
# Sets up a cloudstore NFS server on a Cloud VPS instance in a way to provide
# a flexible test bed.
#
# Params:
#
#  [*main_iface*]
#    Usually just eth0, but represents the name of the interface on the instance
#    to use for communication. Instances are not likely to have multiple
#    interfaces
#    Default: eth0
#
#  [*active_nfs*]
#    Currently active NFS server hostname (not FQDN)
#
#  [*nfs_host1*]
#    NFS host that is intended to be active in a non-failover situation.
#
#  [*nfs_host2*]
#    NFS host that is intended to be standby in a non-failover situation.
#
#  [*nfs_host1_ip*]
#    IPv4 address of the host that is intended to be active in a non-failover
#    situation.
#
#  [*nfs_host2_ip*]
#    IPv4 address of the host that is intended to be standby in a non-failover
#    situation.
#
class profile::wmcs::nfs::test(
  String $main_iface = lookup('profile::wmcs::nfs::test::main_iface', { default_value => 'eth0' }),
  Stdlib::Host $active_nfs = lookup('profile::wmcs::nfs::test::active_nfs'),
  Stdlib::Host $nfs_host1 = lookup('profile::wmcs::nfs::test::nfs_host1'),
  Stdlib::Host $nfs_host2 = lookup('profile::wmcs::nfs::test::nfs_host2'),
  Stdlib::IP::Address $nfs_host1_ip = lookup('profile::wmcs::nfs::test::nfs_host1_ip'),
  Stdlib::IP::Address $nfs_host2_ip = lookup('profile::wmcs::nfs::test::nfs_host2_ip'),
) {
    require profile::openstack::eqiad1::observerenv

    class {'labstore':
        nfsd_threads => 8,
    }

    package { [
            'python3-pymysql',
        ]:
        ensure => present,
    }

    sysctl::parameters { 'cloudstore base':
        values   => {
            # Increase TCP max buffer size
            'net.core.rmem_max' => 67108864,
            'net.core.wmem_max' => 67108864,

            # Increase Linux auto-tuning TCP buffer limits
            # Values represent min, default, & max num. of bytes to use.
            'net.ipv4.tcp_rmem' => [ 4096, 87380, 33554432 ],
            'net.ipv4.tcp_wmem' => [ 4096, 65536, 33554432 ],
        },
        priority => 70,
    }

    class {'labstore::fileserver::exports':
        server_vols   => ['project', 'home'],
    }

    if $facts['hostname'] == $active_nfs {
        $drbd_role = 'primary'
    } else {
        $drbd_role = 'secondary'
    }

    $drbd_resource_config = {
        'test'   => {
            port       => 7790,
            device     => '/dev/drbd1',
            disk       => '/dev/vd/test',
            mount_path => '/srv/test',
        },
        'tools'  => {
            port       => 7791,
            device     => '/dev/drbd4',
            disk       => '/dev/vd/tools-project',
            mount_path => '/srv/tools',
        },
        'misc' => {
            port       => 7792,
            device     => '/dev/drbd3',
            disk       => '/dev/vd/misc-project',
            mount_path => '/srv/misc',
        },
    }

    $drbd_defaults = {
        'drbd_cluster' => {
            $nfs_host1 => $nfs_host1_ip,
            $nfs_host2 => $nfs_host2_ip,
        },
    }

    $cluster_ips_ferm = join([$nfs_host1_ip, $nfs_host2_ip], ' ')
    ferm::service { 'drbd-test':
        proto  => 'tcp',
        port   => '7790',
        srange => "(${cluster_ips_ferm})",
    }

    ferm::service { 'drbd-misc':
        proto  => 'tcp',
        port   => '7791',
        srange => "(${cluster_ips_ferm})",
    }

    ferm::service { 'drbd-tools':
        proto  => 'tcp',
        port   => '7792',
        srange => "(${cluster_ips_ferm})",
    }

    create_resources(labstore::drbd::resource, $drbd_resource_config, $drbd_defaults)

    # state managed manually
    service { 'drbd':
        enable => false,
    }

    # state via nfs-manage
    service { 'nfs-server':
        enable => false,
    }
    $nfs_start_command = 'systemctl start nfs-server'
    $nfs_stop_command = 'systemctl stop nfs-server'

    file { '/usr/local/sbin/nfs-manage':
        content => template('profile/wmcs/nfs/nfs-manage.sh.erb'),
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
    }

    file {'/usr/local/sbin/logcleanup':
        source => 'puppet:///modules/labstore/logcleanup.py',
        mode   => '0744',
        owner  => 'root',
        group  => 'root',
    }

    file {'/etc/logcleanup-config.yaml':
        source => 'puppet:///modules/profile/wmcs/nfs/primary/logcleanup-config.yaml',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }
}
