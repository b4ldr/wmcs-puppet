class profile::openstack::eqiad1::nova::compute::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    $network_flat_interface = lookup('profile::openstack::eqiad1::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = lookup('profile::openstack::eqiad1::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = lookup('profile::openstack::eqiad1::nova::network_flat_interface_vlan'),
    $network_flat_name = lookup('profile::openstack::eqiad1::neutron::network_flat_name'),
    $physical_interface_mappings = lookup('profile::openstack::eqiad1::nova::physical_interface_mappings'),
    String $libvirt_cpu_model = lookup('profile::openstack::eqiad1::nova::libvirt_cpu_model'),
    Optional[Boolean] $enable_nova_rbd = lookup('profile::ceph::client::rbd::enable_nova_rbd', {'default_value' => false}),
    Optional[String] $ceph_rbd_pool = lookup('profile::ceph::client::rbd::pool', {'default_value' => undef}),
    Optional[String] $ceph_rbd_client_name = lookup('profile::ceph::client::rbd::client_name', {'default_value' => undef}),
    Optional[String] $libvirt_rbd_uuid = lookup('profile::ceph::client::rbd::libvirt_rbd_uuid', {'default_value' => undef}),
    ) {

    require ::profile::openstack::eqiad1::neutron::common
    class {'::profile::openstack::base::neutron::linuxbridge_agent':
        version                     => $version,
        physical_interface_mappings => $physical_interface_mappings,
    }
    contain '::profile::openstack::base::neutron::linuxbridge_agent'

    require ::profile::openstack::eqiad1::nova::common
    class {'::profile::openstack::base::nova::compute::service':
        version                            => $version,
        network_flat_interface             => $network_flat_interface,
        network_flat_tagged_base_interface => $network_flat_tagged_base_interface,
        network_flat_interface_vlan        => $network_flat_interface_vlan,
        all_cloudvirts                     => unique(concat(query_nodes('Class[profile::openstack::eqiad1::nova::compute::service]'), [$::fqdn])),
        libvirt_cpu_model                  => $libvirt_cpu_model,
        require                            => Class['::profile::openstack::base::neutron::linuxbridge_agent'],
        ceph_rbd_pool                      => $ceph_rbd_pool,
        ceph_rbd_client_name               => $ceph_rbd_client_name,
        libvirt_rbd_uuid                   => $libvirt_rbd_uuid,
        enable_nova_rbd                    => $enable_nova_rbd,
    }
    contain '::profile::openstack::base::nova::compute::service'

    class {'::openstack::nova::compute::monitor':
        active           => true,
        verify_instances => true,
        contact_groups   => 'wmcs-team,admins',
    }
    contain '::openstack::nova::compute::monitor'
}
