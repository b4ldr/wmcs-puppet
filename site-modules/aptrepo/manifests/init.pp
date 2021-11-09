# == Class: aptrepo
#
#   Configures apt.wikimedia.org and reprepro on a server
#
# === Parameters
#
#   - *basedir*: The reprepro base directory.
#   - *homedir*: The reprepro user home directory.
#   - *user*: The user name to run reprepro under.
#   - *group*: The group name to run reprepro under.
#   - *notify_address*: Where to send upload notifications.
#   - *options*: A list of options for reprepro (see conf/options file).
#   - *uploaders*: A list of uploaders instructions (see "uploaders file")
#   - *incomingdir*: Path considered for incoming uploads.
#   - *incomingconf*: Name of a template with config options for incoming uploads. (conf/incoming)
#   - *incominguser*: The user name that owns the incoming directory.
#   - *incominggroup*: The group name that owns the incoming directory.
#   - *default_distro*: The default distribution if none specified.
#   - *gpg_secring*: The GPG secret keyring for reprepro to use. Will be passed to secret()
#   - *gpg_pubring*: The GPG public keyring for reprepro to use. Will be passed to secret()
#   - *authorized_keys*: A list of ssh public keys allowed to upload and process the incoming queue
#
# === Example
#
#   class { 'aptrepo':
#       basedir => "/tmp/reprepro",
#   }
#
# TODO: add something that sets up /etc/environment for reprepro
#
class aptrepo (
    $basedir,
    $homedir         = '/var/lib/reprepro',
    $user            = 'reprepro',
    $group           = 'reprepro',
    $notify_address  = 'root@wikimedia.org',
    $options         = [],
    $uploaders       = [],
    $incomingdir     = 'incoming',
    $incomingconf    = 'incoming',
    $incominguser    = 'reprepro',
    $incominggroup   = 'reprepro',
    $default_distro  = 'buster',
    $gpg_secring     = undef,
    $gpg_pubring     = undef,
    $gpg_user        = undef,
    $authorized_keys = [],
) {

    ensure_packages([
        'reprepro',
        'dpkg-dev',
        'dctrl-tools',
        'gnupg',
        'python-apt',
    ])

    $deb822_validate_cmd = '/usr/bin/python -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"'

    file { $basedir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${basedir}/conf":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${basedir}/conf/updates":
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/updates',
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/pulls":
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/pulls',
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/options":
        ensure       => file,
        owner        => $user,
        group        => $group,
        mode         => '0444',
        content      => inline_template("<%= @options.join(\"\n\") %>\n"),
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/uploaders":
        ensure       => file,
        owner        => $user,
        group        => $group,
        mode         => '0444',
        content      => inline_template("<%= @uploaders.join(\"\n\") %>\n"),
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/incoming":
        ensure       => present,
        owner        => 'root',
        group        => 'root',
        mode         => '0444',
        content      => template("aptrepo/${incomingconf}.erb"),
        validate_cmd => $deb822_validate_cmd,
    }

    $log_script = @("SCRIPT"/$)
    #!/bin/bash
    echo -e "reprepro changes:\n\$@" | mail -s "Reprepro changes" ${notify_address}
    | SCRIPT
    file { "${basedir}/conf/log":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => $log_script,
    }

    file { "${basedir}/db":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/incoming":
        ensure => directory,
        mode   => '1775',
        owner  => $incominguser,
        group  => $incominggroup,
    }

    file { "${basedir}/logs":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/tmp":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${homedir}/.gnupg":
        ensure  => directory,
        owner   => $gpg_user,
        group   => $gpg_user,
        mode    => '0700',
        require => User['reprepro'],
    }

    ssh::userkey { 'reprepro':
        content => template('aptrepo/authorized_keys.erb'),
    }

    file { '/usr/local/bin/reprepro-ssh-upload':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => User['reprepro'],
        source  => 'puppet:///modules/aptrepo/reprepro-ssh-upload',
    }

    if $gpg_secring != undef {
        file { "${homedir}/.gnupg/secring.gpg":
            ensure    => file,
            owner     => $gpg_user,
            group     => $gpg_user,
            mode      => '0400',
            content   => secret($gpg_secring),
            show_diff => false,
            require   => User['reprepro'],
        }
    }

    if $gpg_pubring != undef {
        file { "${homedir}/.gnupg/pubring.gpg":
            ensure  => file,
            owner   => $gpg_user,
            group   => $gpg_user,
            mode    => '0400',
            content => secret($gpg_pubring),
            require => User['reprepro'],
        }
    }

    file { '/root/.gnupg/reprepro-updates-keys.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        recurse => true,
        purge   => true,
        source  => 'puppet:///modules/aptrepo/updates-keys',
        notify  => Exec['reprepro-import-updates-keys'],
    }

    exec { 'reprepro-import-updates-keys':
        refreshonly => true,
        provider    => 'shell',
        command     => '/usr/bin/gpg --import /root/.gnupg/reprepro-updates-keys.d/*.gpg',
    }

    file_line { 'reprepro_basedir':
      ensure => present,
      path   => '/root/.bashrc',
      line   => "export REPREPRO_BASE_DIR=${basedir}  # Managed by puppet",
    }

    # We also need /srv/tftboot populated from volatile on APT repo servers,
    # not just install (TFTP) servers because installer files are fetched via HTTP (T252382)
    file { '/srv/tftpboot':
        # config files in the puppet repository,
        # larger files like binary images in volatile
        source       => [
            'puppet:///modules/install_server/tftpboot',
            # lint:ignore:puppet_url_without_modules
            'puppet:///volatile/tftpboot',
            # lint:endignore
        ],
        sourceselect => all,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        recurse      => remote,
        backup       => false,
    }
}
