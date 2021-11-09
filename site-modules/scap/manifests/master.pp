# = class: scap::master
#
# Sets up a scap master (currently deploy1002 and deploy2002)
class scap::master(
    Stdlib::Unixpath $common_path        = '/srv/mediawiki',
    Stdlib::Unixpath $common_source_path = '/srv/mediawiki-staging',
    Stdlib::Unixpath $patches_path       = '/srv/patches',
    String $deployment_group             = 'wikidev',
    Array[String] $deployment_hosts      = [],
){
    include network::constants

    ensure_packages(['python3-service-checker', 'python3-pygerrit2'])

    git::clone { 'operations/mediawiki-config':
        ensure             => present,
        directory          => $common_source_path,
        owner              => 'mwdeploy',
        group              => $deployment_group,
        shared             => true,
        before             => Exec['fetch_mediawiki'],
        recurse_submodules => true,
    }

    # Install the commit-msg hook from gerrit

    file { "${common_source_path}/.git/hooks/commit-msg":
        ensure  => present,
        owner   => 'mwdeploy',
        group   => $deployment_group,
        mode    => '0775',
        source  => 'puppet:///modules/scap/commit-msg',
        require => Git::Clone['operations/mediawiki-config'],
    }

    rsync::server::module { 'common':
        path        => $common_source_path,
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

    rsync::server::module { 'patches':
        path        => $patches_path,
        read_only   => 'yes',
        hosts_allow => $deployment_hosts
    }

    class { 'scap::l10nupdate':
        deployment_group => $deployment_group,
        run_l10nupdate   => false,
    }

    file { '/usr/local/bin/scap-master-sync':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/scap-master-sync',
    }

    # Allow rsync of common module to mediawiki-staging as root.
    # This is for master-master sync of /srv/mediawiki-staging
    sudo::user { 'scap-master-sync':
        user       => 'mwdeploy',
        privileges => [
            'ALL = (root) NOPASSWD: /usr/local/bin/scap-master-sync',
        ]
    }
}
