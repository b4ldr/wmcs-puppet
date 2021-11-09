# Class package_builder::hooks
# A wrapper class for package::pbuilder_hooks. Mostly exists to make the
# addition of new distributions as easy as possible
class package_builder::hooks(
    Stdlib::Unixpath $basepath='/var/cache/pbuilder',
) {
    file { "${basepath}/hooks":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    package_builder::pbuilder_hook { 'stretch':
        distribution => 'stretch',
        components   => 'main',
        basepath     => $basepath,
    }

    package_builder::pbuilder_hook { 'buster':
        distribution => 'buster',
        components   => 'main',
        basepath     => $basepath,
    }

    package_builder::pbuilder_hook { 'bullseye':
        distribution => 'bullseye',
        components   => 'main',
        basepath     => $basepath,
    }
}
