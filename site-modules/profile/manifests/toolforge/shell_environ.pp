# This class sets up a node as a shell dev environment for Toolforge.
#
# Those are the dependencies for development tools and packages intended
# for interactive use in a shell.  Most actual libraries are in exec_environ.

class profile::toolforge::shell_environ {
    if debian::codename::eq('stretch') {
        include profile::toolforge::genpp::python_dev_stretch
    }

    package { [
        'apt-file',
        'cvs',  # Because I don't think webhooks or other uses exist anymore outside cli
        'dh-make-perl',
        'elinks',
        'emacs',
        'fakeroot', # for dpkg
        'flex',                        # T114003.
        'ipython',                     # T58995
        'joe',                         # T64236.
        'links',
        'lintian',
        'lynx',
        'mc', # Popular{{cn}} on Toolserver
        'neovim',                      # T219501
        'pastebinit',
        'pep8',                        # T59863
        'rlwrap',                      # T87368
        'tig',
        'valgrind',                    # T87117.
    ]:
        ensure => latest,
    }

    # redis-tools won't install from stretch-backports due to a dependency
    #  foul-up, so work around this for existing stretch hosts.
    # This won't help for new stretch hosts! If you're trying to do that
    #  my only advice is... don't?
    if debian::codename::eq('stretch') {
        package  { 'redis-tools':
            ensure => 'present',
        }
    } else {
        package  { 'redis-tools':
            ensure => 'latest',
        }
    }

    # pastebinit configuration for https://tools.wmflabs.org/paste/.
    file { '/etc/pastebin.d':
        ensure  => 'directory',
        require => Package['pastebinit'],
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    file { '/etc/pastebin.d/tools.conf':
        ensure  => 'file',
        require => File['/etc/pastebin.d'],
        source  => 'puppet:///modules/profile/toolforge/pastebinit.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
