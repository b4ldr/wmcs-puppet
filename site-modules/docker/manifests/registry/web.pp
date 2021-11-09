class docker::registry::web(
    Boolean $use_puppet_certs = false,
    Boolean $use_acme_chief_certs = false,
    Boolean $http_endpoint = false,
    Array[Stdlib::Host] $http_allowed_hosts = [],
    Boolean $cors = false,
    Optional[String] $docker_username,
    Optional[String] $docker_password_hash,
    Optional[Array[Stdlib::Host]] $allow_push_from,
    Optional[Array[String]] $ssl_settings,
    Optional[String] $ssl_certificate_name = undef,
) {
    if (!$use_puppet_certs and ($ssl_certificate_name == undef)) {
        fail('Either puppet certs should be used, or an ssl cert name should be provided')
    }

    if $use_puppet_certs {
        base::expose_puppet_certs { '/etc/nginx':
            ensure          => present,
            provide_private => true,
            require         => Class['nginx'],
        }
    }

    file { '/etc/nginx/htpasswd.registry':
        content => "${docker_username}:${docker_password_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx-common'],
    }
    nginx::site { 'registry':
        content => template('docker/registry-nginx.conf.erb'),
    }

    if $http_endpoint {
        nginx::site { 'registry-http':
            content => template('docker/registry-http-nginx.conf.erb'),
        }
    }

}
