# Class: dnsrecursor
#
# [*listen_addresses]
#  Addresses the DNS recursor should listen on for queries
#
# [*allow_from]
#  Prefixes from which to allow recursive DNS queries

class dnsrecursor(
    $listen_addresses         = [$::ipaddress],
    $allow_from               = [],
    $additional_forward_zones = '',
    $auth_zones               = undef,
    $lua_hooks                = undef,
    $max_cache_entries        = 1000000,
    $max_negative_ttl         = 3600,
    $max_tcp_clients          = 128,
    $max_tcp_per_client       = 100,
    $client_tcp_timeout       = 2,
    $export_etc_hosts         = 'off',
    $version_hostname         = false,
    $dnssec                   = 'off', # T226088 T227415 - off until at least 4.1.x
    $threads                  = 4,
    $log_common_errors        = 'yes',
    $bind_service             = undef,
    $allow_from_listen        = true,
    $allow_forward_zones      = true,
    $allow_edns_whitelist     = true,
    $allow_incoming_ecs       = false,
    $allow_qname_minimisation = false,
    $install_from_component   = false, # for buster, enable pdns-recursor from component
) {

    include ::network::constants
    $wmf_authdns = [
        '208.80.154.238',
        '208.80.153.231',
        '91.198.174.239',
    ]
    $wmf_authdns_semi = join($wmf_authdns, ';')
    $forward_zones = "wmnet=${wmf_authdns_semi}, 10.in-addr.arpa=${wmf_authdns_semi}"

    # systemd unit fragment to raise ulimits and other things
    $sysd_dir = '/etc/systemd/system/pdns-recursor.service.d'
    $sysd_frag = "${sysd_dir}/override.conf"

    file { $sysd_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $sysd_frag:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dnsrecursor/override.conf.erb'),
    }

    exec { "systemd reload for ${sysd_frag}":
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => File[$sysd_frag],
        before      => Service['pdns-recursor'],
    }

    if debian::codename::eq('buster') and $install_from_component {
        apt::package_from_component { 'pdns-recursor':
            component => 'component/pdns-recursor',
        }
    } else {
        package { 'pdns-recursor':
            ensure => 'present',
        }
    }

    file { '/etc/powerdns/recursor.conf':
        ensure  => 'present',
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pdns-recursor'],
        content => template('dnsrecursor/recursor.conf.erb'),
    }

    if $lua_hooks {
        file { '/etc/powerdns/recursorhooks.lua':
            ensure  => 'present',
            require => Package['pdns-recursor'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Service['pdns-recursor'],
            content => template('dnsrecursor/recursorhooks.lua.erb'),
        }
    }

    service { 'pdns-recursor':
        ensure    => 'running',
        require   => [Package['pdns-recursor'],
                      File['/etc/powerdns/recursor.conf']
        ],
        subscribe => File['/etc/powerdns/recursor.conf'],
        pattern   => 'pdns_recursor',
        hasstatus => false,
    }
}
