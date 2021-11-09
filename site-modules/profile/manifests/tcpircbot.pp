class profile::tcpircbot(
    Wmflib::Ensure $ensure = present,
    Stdlib::Host $irc_host = lookup('profile::tcpircbot::irc::host'),
    Stdlib::Port $irc_port = lookup('profile::tcpircbot::irc::port'),
){

    include passwords::logmsgbot
    include ::tcpircbot

    tcpircbot::instance { 'logmsgbot':
        ensure      => $ensure,
        channels    => '#wikimedia-operations',
        password    => $passwords::logmsgbot::logmsgbot_password,
        server_host => $irc_host,
        server_port => $irc_port,
        cidr        => [
            '::ffff:127.0.0.1/128',             # loopback
            '::ffff:10.64.32.28/128',           # deployment eqiad v4: deploy1002
            '2620:0:861:103:10:64:32:28/128',   # deployment eqiad v6: deploy1002
            '::ffff:10.64.16.77/128',           # maintenance eqiad v4: mwmaint1002
            '2620:0:861:102:10:64:16:77/64',    # maintenance eqiad v6: mwmaint1002
            '::ffff:10.192.32.34/128',          # maintenance codfw v4: mwmaint2002
            '2620:0:860:103:10:192:32:34/64',   # maintenance codfw v6: mwmaint2002
            '::ffff:10.64.16.73/128',           # puppetmaster1001.eqiad.wmnet
            '2620:0:861:102:10:64:16:73/128',   # puppetmaster1001.eqiad.wmnet
            '::ffff:10.192.0.27/128',           # puppetmaster2001.codfw.wmnet
            '2620:0:860:101:10:192:0:27/128',   # puppetmaster2001.codfw.wmnet
            '::ffff:10.64.32.25/128',           # cumin1001.eqiad.wmnet
            '2620:0:861:103:10:64:32:25/64',    # cumin1001.eqiad.wmnet
            '::ffff:10.192.48.16/128',          # cumin2001.codfw.wmnet
            '2620:0:860:101:10:192:48:16/64',   # cumin2001.codfw.wmnet
            '::ffff:10.192.32.49/128',          # cumin2002.codfw.wmnet
            '2620:0:860:103:10:192:32:49/64',   # cumin2002.codfw.wmnet
        ],
    }
    nrpe::monitor_service { 'tcpircbot':
        ensure => 'absent'
    }

    $allowed_hosts = [
        'deploy1002.eqiad.wmnet',       # deployment eqiad
        'deploy2002.codfw.wmnet',       # deployment codfw
        'puppetmaster1001.eqiad.wmnet', # puppet eqiad
        'puppetmaster2001.codfw.wmnet', # puppet codfw
        'mwmaint1002.eqiad.wmnet',      # maintenance eqiad
        'mwmaint2002.codfw.wmnet',      # maintenance codfw
        'cumin1001.eqiad.wmnet',        # cluster mgmt eqiad
        'cumin2001.codfw.wmnet',        # cluster mgmt codfw
        'cumin2002.codfw.wmnet',        # cluster mgmt codfw
    ]

    $allowed_hosts_ferm = join($allowed_hosts, ' ')
    ferm::service { 'tcpircbot_allowed':
        proto  => 'tcp',
        port   => '9200',
        srange => "(@resolve((${allowed_hosts_ferm})) @resolve((${allowed_hosts_ferm}), AAAA))",
    }
}
