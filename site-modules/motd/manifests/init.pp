# == Class: motd
#
# Module for customizing MOTD (Message of the Day) banners.
#
class motd {
    # Kill Debian's default copyright/warranty banner
    file { '/etc/motd':
        ensure => absent,
    }

    file { '/etc/update-motd.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    include motd::defaults
}
