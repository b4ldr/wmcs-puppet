class profile::cache::haproxy(
    Stdlib::Port $tls_port = lookup('profile::cache::haproxy::tls_port'),
    Stdlib::Port $prometheus_port = lookup('profile::cache::haproxy::prometheus_port', {'default_value' => 9422}),
    Hash[String, Haproxy::Tlscertificate] $available_unified_certificates = lookup('profile::cache::haproxy::available_unified_certificates'),
    Optional[Hash[String, Haproxy::Tlscertificate]] $extra_certificates = lookup('profile::cache::haproxy::extra_certificates', {'default_value' => undef}),
    Optional[Array[String]] $unified_certs = lookup('profile::cache::haproxy::unified_certs', {'default_value' => undef}),
    Boolean $unified_acme_chief = lookup('profile::cache::haproxy::unified_acme_chief'),
    Stdlib::Unixpath $varnish_socket = lookup('profile::cache::haproxy::varnish_socket'),
    String $tls_ciphers = lookup('profile::cache::haproxy::tls_ciphers'),
    String $tls13_ciphers = lookup('profile::cache::haproxy::tls13_ciphers'),
    Integer[0] $tls_cachesize = lookup('profile::cache::haproxy::tls_cachesize'),
    Integer[0] $tls_session_lifetime = lookup('profile::cache::haproxy::tls_session_lifetime'),
    Haproxy::Timeout $timeout = lookup('profile::cache::haproxy::timeout'),
    Haproxy::H2settings $h2settings = lookup('profile::cache::haproxy::h2settings'),
    Haproxy::Proxyprotocol $proxy_protocol = lookup('profile::cache::haproxy::proxy_protocol'),
    Array[Haproxy::Var] $vars = lookup('profile::cache::haproxy::vars'),
    Array[Haproxy::Acl] $acls = lookup('profile::cache::haproxy::acls'),
    Array[Haproxy::Header] $add_headers = lookup('profile::cache::haproxy::add_headers'),
    Array[Haproxy::Header] $del_headers = lookup('profile::cache::haproxy::del_headers'),
    Boolean $do_ocsp = lookup('profile::cache::haproxy::do_ocsp'),
    String $ocsp_proxy = lookup('http_proxy'),
    String $public_tls_unified_cert_vendor=lookup('public_tls_unified_cert_vendor'),
) {
    class { '::sslcert::dhparam': }

    # variables used inside HAProxy's systemd unit
    $pid = '/run/haproxy/haproxy.pid'
    $exec_start = '/usr/sbin/haproxy -Ws'


    # Use HAProxy 2.2 from buster-backports
    apt::pin { 'haproxy-buster-bpo':
        package  => 'haproxy',
        pin      => 'release n=buster-backports',
        priority => 1002,
        before   => Class['::haproxy'],
    }

    class { '::haproxy':
        template        => 'profile/cache/haproxy.cfg.erb',
        systemd_content => template('profile/cache/haproxy.service.erb'),
        logging         => false,
    }

    ensure_packages('python3-pystemd')
    file { '/usr/local/sbin/haproxy-stek-manager':
        ensure => present,
        source => 'puppet:///modules/profile/cache/haproxy_stek_manager.py',
        owner  => root,
        group  => root,
        mode   => '0544',
    }

    systemd::tmpfile { 'haproxy_secrets_tmpfile':
        content => 'd /run/haproxy-secrets 0700 haproxy haproxy -',
    }

    $tls_ticket_keys_path = '/run/haproxy-secrets/stek.keys'
    systemd::timer::job { 'haproxy_stek_job':
        ensure      => present,
        description => 'HAProxy STEK manager',
        command     => "/usr/local/sbin/haproxy-stek-manager ${tls_ticket_keys_path}",
        interval    => [
            {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00/8:00:00', # every 8 hours
            },
            {
            'start'    => 'OnBootSec',
            'interval' => '0sec',
            },
        ],
        user        => 'root',
        require     => File['/usr/local/sbin/haproxy-stek-manager'],
    }

    if !$available_unified_certificates[$public_tls_unified_cert_vendor] {
        fail('The specified TLS unified cert vendor is not available')
    }

    unless empty($unified_certs) {
        $unified_certs.each |String $cert| {
            sslcert::certificate { $cert:
                before => Haproxy::Site['tls']
            }

            if $do_ocsp {
                sslcert::ocsp::conf { $cert:
                    proxy  => $ocsp_proxy,
                    before => Service['haproxy'],
                }
                # HAProxy expects the prefetched OCSP response on the same path as the certificate
                file { "/etc/ssl/private/${cert}.crt.key.ocsp":
                    ensure  => link,
                    target  => "/var/cache/ocsp/${cert}.ocsp",
                    require => Sslcert::Ocsp::Conf[$cert],
                }
            }
        }
        if $do_ocsp {
            sslcert::ocsp::hook { 'haproxy-ocsp':
                content => file('profile/cache/update_ocsp_haproxy_hook.sh'),
            }
        }
    }

    if $unified_acme_chief {
        acme_chief::cert { 'unified':
            puppet_svc => 'haproxy',
            key_group  => 'haproxy',
        }
    }

    if !empty($extra_certificates) {
        $extra_certificates.each |String $extra_cert_name, Hash $extra_cert| {
            acme_chief::cert { $extra_cert_name:
                puppet_svc => 'haproxy',
                key_group  => 'haproxy',
            }
        }
        $certificates = [$available_unified_certificates[$public_tls_unified_cert_vendor]] + values($extra_certificates)
    } else {
        $certificates = [$available_unified_certificates[$public_tls_unified_cert_vendor]]
    }

    file { '/etc/haproxy/tls.lua':
        owner   => 'haproxy',
        group   => 'haproxy',
        mode    => '0444',
        content => file('profile/cache/haproxy-tls.lua'),
        before  => Service['haproxy'],
        notify  => Service['haproxy'],
    }

    haproxy::tls_terminator { 'tls':
        port                 => $tls_port,
        backend_socket       => $varnish_socket,
        certificates         => $certificates,
        tls_ciphers          => $tls_ciphers,
        tls13_ciphers        => $tls13_ciphers,
        timeout              => $timeout,
        h2settings           => $h2settings,
        proxy_protocol       => $proxy_protocol,
        tls_cachesize        => $tls_cachesize,
        tls_session_lifetime => $tls_session_lifetime,
        tls_ticket_keys_path => $tls_ticket_keys_path,
        lua_scripts          => ['/etc/haproxy/tls.lua'],
        vars                 => $vars,
        acls                 => $acls,
        add_headers          => $add_headers,
        del_headers          => $del_headers,
        prometheus_port      => $prometheus_port,
    }
}
