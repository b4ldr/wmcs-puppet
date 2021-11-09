class role::wmcs::openstack::codfw1dev::virt {
    system::role { $name: }
    include ::profile::base::production
    # include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::observerenv
    include ::profile::openstack::codfw1dev::nova::common
    include ::profile::openstack::codfw1dev::nova::compute::service
    include ::profile::openstack::codfw1dev::envscripts
    include ::profile::ceph::client::rbd_libvirt
}
