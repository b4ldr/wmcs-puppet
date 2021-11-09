class openstack::designate::service::victoria
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::victoria::${::lsbdistcodename}"

    $packages = [
        'designate-sink',
        'designate-common',
        'designate-mdns',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
        'python-git',
        'python3-git',
    ]

    package { $packages:
        ensure => 'present',
    }
}
