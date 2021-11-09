# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::common(
) {
    requires_realm('labs')

    if debian::codename::le('buster') {
        $py2packages = [
            'python-novaclient',
            'python-glanceclient',
            'python-keystoneclient',
            'python-openstackclient',
            'python-designateclient',
            'python-neutronclient',
            'python-netaddr',
        ]
        ensure_packages($py2packages)
    }

    $py3packages = [
        'python3-novaclient',
        'python3-glanceclient',
        'python3-keystoneauth1',
        'python3-keystoneclient',
        'python3-openstackclient',
        'python3-designateclient',
        'python3-neutronclient',
        'python3-troveclient',
        'python3-netaddr',
    ]
    ensure_packages($py3packages)

    $otherpackages = [
        'ebtables',
    ]
    ensure_packages($otherpackages)

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients3.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
