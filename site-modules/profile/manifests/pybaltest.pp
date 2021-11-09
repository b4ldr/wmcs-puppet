class profile::pybaltest (
    Array[Stdlib::Host] $hosts = lookup('profile::pybaltest::hosts'),
) {
    $hosts_str = $hosts.join(' ')
    ferm::service { 'pybaltest-http':
        proto  => 'tcp',
        port   => '80',
        srange => "(@resolve((${hosts_str})) @resolve((${hosts_str}), AAAA))",
    }

    ferm::service { 'pybaltest-bgp':
        proto  => 'tcp',
        port   => '179',
        srange => "(@resolve((${hosts_str})) @resolve((${hosts_str}), AAAA))",
    }

    # If the host considers itself as a router (IP forwarding enabled), it will
    # ignore all router advertisements, breaking IPv6 SLAAC. Accept Router
    # Advertisements even if forwarding is enabled.
    sysctl::parameters { 'accept-ra':
        values => {
            "net.ipv6.conf.${facts['interface_primary']}.accept_ra" => 2,
        },
    }

    # Install conftool-master for conftool testing
    class  { 'puppetmaster::base_repo':
        gitdir   => '/var/lib/git',
        gitowner => 'root',
    }
}
