# == Define: profile::openstack::base::haproxy::site
#
# Configures a HAProxy layer7 backend and frontend configuration for the
# requested service endpoint.
#
# === Parameters
#
# [*ensure*]
#   Wmflib Ensure (string)
#   'present' or 'absent'; whether the site configuration is
#   installed or removed in conf.d/
#
# [*port_backend*]
#   Port (int)
#   The backend port HAProxy will use to connect to the backend servers.
#
# [*port_frontend*]
#   Port (int)
#   The frontend port HAproxy will bind to for this service.
#
# [*primary_host*]
#   Stdlib::Fqdn
#   When specified, the primary host will be the only active service;
#   others will be marked as backups. If this item is set but not
#   a member of the $servers below, all servers will be marked as backups
#   and nothing much will work.
#
# [*servers*]
#   Array of Stdlib::Fqdn
#   A list of backend servers providing the service.
#
# [*healthcheck_method*]
#   HTTP Method (String)
#   The HTTP request method to use for the healthcheck

# [*healthcheck_options*]
#   Array of Strings
#   A list of healthcheck (http-check) options
#
#
# === Examples
#
#  profile::openstack::base::haproxy::site { 'nova_metadata':
#      port_frontend => '8775',
#      port_backend  => '18775',
#      servers       => ['backend-host01', 'backend-host02'],
#  }
#
define profile::openstack::base::haproxy::site(
    Array[Stdlib::Fqdn] $servers,
    Stdlib::Port $port_backend,
    Stdlib::Port $port_frontend,
    Optional[Stdlib::Fqdn] $primary_host = undef,
    Stdlib::Compat::String $healthcheck_path = '',
    String $healthcheck_method = '',
    Array[String] $healthcheck_options = [],
    Wmflib::Ensure $ensure = present,
    Enum['http', 'tcp'] $type = 'http',
    Optional[String] $frontend_tls_cert_name = undef,
    Optional[Stdlib::Port] $port_frontend_tls = undef,
) {
    include profile::openstack::base::haproxy

    $cert_file = $frontend_tls_cert_name ? {
        undef   => undef,
        default => "/etc/acmecerts/${frontend_tls_cert_name}/live/ec-prime256v1.chained.crt.key"
    }

    # If the host's FQDN is in $servers configure FERM to allow peer
    # connections on the backend service port.
    if $::fqdn in $servers {
        # Allow traffic to peers on backend ports
        $peers = join(delete($servers, $::fqdn), ' ')
        ferm::service { "${title}_haproxy_backend":
            proto  => 'tcp',
            port   => $port_backend,
            srange => "(@resolve((${peers})) @resolve((${peers}), AAAA))",
        }
    }

    if $type == 'http' {
        file { "/etc/haproxy/conf.d/${title}.cfg":
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('profile/openstack/base/haproxy/conf.d/http-service.cfg.erb'),
            # restart to pick up new config files in conf.d
            notify  => Service['haproxy'],
        }
    } elsif $type == 'tcp' {
        file { "/etc/haproxy/conf.d/${title}.cfg":
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('profile/openstack/base/haproxy/conf.d/tcp-service.cfg.erb'),
            # restart to pick up new config files in conf.d
            notify  => Service['haproxy'],
        }

        if $frontend_tls_cert_name != undef or $frontend_tls_cert_name != undef {
            fail('TLS termination is not supported for type="tcp"')
        }
    } else {
        fail("Unknown service type ${type}")
    }
}
