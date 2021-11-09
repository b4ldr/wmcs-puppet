# Class: profile::wmcs::nfs::standalone
#
# Sets up an Openstack instance-based NFS server
#
class profile::wmcs::nfs::standalone(
    Boolean $cinder_attached = lookup('profile::wcms::nfs::standalone::cinder_attached'),
    Array[String] $volumes   = lookup('profile::wcms::nfs::standalone::volumes'),
) {
    require profile::openstack::eqiad1::observerenv

    class {'cloudnfs': }

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

    class {'cloudnfs::fileserver::exports':
        server_vols     => $volumes,
        cinder_attached => $cinder_attached,
    }

    # state manually managed
    service { 'nfs-server':
        enable => false,
    }

    file {'/usr/local/sbin/logcleanup':
        source => 'puppet:///modules/cloudnfs/logcleanup.py',
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
