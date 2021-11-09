class profile::openstack::codfw1dev::haproxy(
    Optional[String] $acme_chief_cert_name = lookup('profile::openstack::codfw1dev::haproxy::acme_chief_cert_name', {default_value => undef}),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Stdlib::Port $glance_api_bind_port = lookup('profile::openstack::codfw1dev::glance::api_bind_port'),
    Stdlib::Port $placement_api_bind_port = lookup('profile::openstack::codfw1dev::placement::api_bind_port'),
    Stdlib::Port $cinder_api_bind_port = lookup('profile::openstack::codfw1dev::cinder::api_bind_port'),
    Stdlib::Port $trove_api_bind_port = lookup('profile::openstack::base::trove::api_bind_port'),
    Stdlib::Port $radosgw_api_bind_port = lookup('profile::openstack::base::radosgw::api_bind_port'),
    Stdlib::Port $barbican_bind_port = lookup('profile::openstack::codfw1dev::barbican::bind_port'),
    Stdlib::Port $keystone_admin_bind_port = lookup('profile::openstack::codfw1dev::keystone::admin_bind_port'),
    Stdlib::Port $keystone_public_bind_port = lookup('profile::openstack::codfw1dev::keystone::public_bind_port'),
    Stdlib::Port $neutron_bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    Stdlib::Port $nova_metadata_listen_port = lookup('profile::openstack::codfw1dev::nova::metadata_listen_port'),
    Stdlib::Port $galera_listen_port = lookup('profile::openstack::codfw1dev::galera::listen_port'),
    Stdlib::Fqdn $galera_primary_host = lookup('profile::openstack::codfw1dev::galera::primary_host'),
    Stdlib::Port $nova_osapi_compute_listen_port = lookup('profile::openstack::codfw1dev::nova::osapi_compute_listen_port'),
) {
    if $acme_chief_cert_name != undef {
        acme_chief::cert { $acme_chief_cert_name:
            puppet_svc => 'haproxy',
        }
    }

    profile::openstack::base::haproxy::site { 'designate':
        servers                => $designate_hosts,
        healthcheck_method     => 'HEAD',
        healthcheck_path       => '/',
        port_frontend          => 9001,
        port_backend           => 9001,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 29001,

    }

    # Note that because keystone admin uses a weird, extremely-high-number
    #  port by default, we need to use a non-standard port for its
    #  tls port as well: 25357 rather than the more expected 225357
    profile::openstack::base::haproxy::site { 'keystone_admin':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 35357,
        port_backend           => $keystone_admin_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 25357,
    }

    profile::openstack::base::haproxy::site { 'keystone_public':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 5000,
        port_backend           => $keystone_public_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 25000,
    }

    profile::openstack::base::haproxy::site { 'glance_api':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 9292,
        port_backend           => $glance_api_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 29292,
    }

    profile::openstack::base::haproxy::site { 'cinder_api':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 8776,
        port_backend           => $cinder_api_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 28776,
    }

    profile::openstack::base::haproxy::site { 'trove_api':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 8779,
        port_backend           => $trove_api_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 28779,
    }

    profile::openstack::base::haproxy::site { 'radosgw_api':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 8080,
        port_backend           => $radosgw_api_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 28080,
    }

    profile::openstack::base::haproxy::site { 'barbican':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 9311,
        port_backend           => $barbican_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 29311,
    }

    profile::openstack::base::haproxy::site { 'neutron':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 9696,
        port_backend           => $neutron_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 29696,
    }

    profile::openstack::base::haproxy::site { 'nova_api':
        servers                => $openstack_controllers,
        healthcheck_method     => 'HEAD',
        healthcheck_path       => '/',
        port_frontend          => 8774,
        port_backend           => $nova_osapi_compute_listen_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 28774,
    }

    profile::openstack::base::haproxy::site { 'placement_api':
        servers                => $openstack_controllers,
        healthcheck_method     => 'GET',
        healthcheck_path       => '/',
        port_frontend          => 8778,
        port_backend           => $placement_api_bind_port,
        frontend_tls_cert_name => $acme_chief_cert_name,
        port_frontend_tls      => 28778,
    }

    profile::openstack::base::haproxy::site { 'nova_metadata':
        servers            => $openstack_controllers,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_frontend      => 8775,
        port_backend       => $nova_metadata_listen_port,
    }

    profile::openstack::base::haproxy::site { 'mysql':
        servers             => $openstack_controllers,
        port_frontend       => 3306,
        port_backend        => $galera_listen_port,
        primary_host        => $galera_primary_host,
        healthcheck_options => ['option httpchk'],
        type                => 'tcp'
    }
}
