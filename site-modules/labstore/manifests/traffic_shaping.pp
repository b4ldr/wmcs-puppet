class labstore::traffic_shaping(
    String $nfs_write = '75mbps',
    String $nfs_read = '75mbps',
    String $nfs_dumps_read = '5000kbps',
    String $egress = '40000kbps',
    String $interface = $facts['networking']['primary'],
) {

    file { '/usr/local/sbin/tc-setup':
        ensure  => present,
        mode    => '0554',
        owner   => 'root',
        group   => 'root',
        content => template('labstore/tc-setup.sh.erb'),
        notify  => Exec['apply_tc_config'],
    }

    # if native qdisc of pfifo_fast is applied then load modules & setup
    exec { 'apply_tc_config':
        command => '/sbin/modprobe ifb numifbs=1 && /sbin/modprobe act_mirred && /usr/local/sbin/tc-setup',
        onlyif  => '/sbin/tc -s qdisc show | /bin/grep "qdisc pfifo"',
    }

    # run when interfaces come up.
    file { '/etc/network/if-up.d/tc':
        ensure  => 'link',
        target  => '/usr/local/sbin/tc-setup',
        require => File['/usr/local/sbin/tc-setup'],
    }

    # under systemd either /etc/modules or /etc/load-modules.d works
    # since labs still has precise instances this is applied
    # using the non-.d model since it is still effective and consistent
    file_line { 'enable_ifb':
        ensure => present,
        line   => 'ifb',
        path   => '/etc/modules',
    }

    file_line { 'enable_act_mirred':
        ensure => present,
        line   => 'act_mirred',
        path   => '/etc/modules',
    }

    # ifb by default creates 2 interfaces
    kmod::options { 'ifb':
        options => 'numifbs=1',
    }
}
