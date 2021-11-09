# Common configuration to be applied on any labs Jenkins slave
#
class profile::ci::slave::labs::common {

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent, eg the java jre.
    include ::profile::java

    # Need the labs instance extended disk space. T277078.
    require ::profile::wmcs::lvm
    require ::profile::labs::lvm::srv

    # base directory
    file { '/srv/jenkins':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => Mount['/srv'],
    }

    file { '/srv/jenkins/cache':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/jenkins'],
    }

    file { '/srv/jenkins/workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/jenkins'],
    }

    # Legacy from /mnt era
    file { '/srv/jenkins-workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',  # useless, but we need a group
        mode    => '0775',
        require => Mount['/srv'],
    }

    file { '/srv/home':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Mount['/srv'],
    }
    file { '/srv/home/jenkins-deploy':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/home'],
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/srv/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::fqdn}",
            },
        },
        require  => File['/srv/home/jenkins-deploy'],
    }
}
