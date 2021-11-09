# == Class profile::analytics::cluster::packages::statistics
#
# Specific packages that should be installed on analytics statistics
# nodes (no Hadoop client related packages).
#
# NOTE: If done carefully, most if not all of the packages declared in this
# class could probably be removed.  It doesn't hurt to have them, but if
# you ever run into an issue (e.g. after an OS upgrade), be bold and
# remove packages at will.
# See also: https://phabricator.wikimedia.org/T275786
#
class profile::analytics::cluster::packages::statistics {

    include ::profile::analytics::cluster::packages::common

    class { '::imagemagick::install': }

    # Needed for the Oct 2021 DSE hackathon
    # More info https://phabricator.wikimedia.org/T292306
    # TBD: do we want to keep them permanently?
    ensure_packages(['libasound2-dev', 'libjack-dev', 'portaudio19-dev'])

    ensure_packages([
        'time',
        'mc',
        'zip',
        'p7zip',
        'p7zip-full',
        'git-review',
        'make',
        'sqlite3',                # For storing and interacting with intermediate results
        'libbz2-dev',             # For compiling some python libs. T84378
        'libmaxminddb-dev',
        'build-essential',        # Requested by halfak to install SciPy
        'libcurl4-openssl-dev',   # Requested by bearloga for an essential R package {devtools}
        'libicu-dev',             # ^
        'libssh2-1-dev',          # ^
        'lynx',                   # Requested by dcausse to be able to inspect yarn's logs from analytics10XX hosts
        'gsl-bin',
        'libgsl-dev',
        'g++',
        'libyaml-cpp-dev',        # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
        'php-cli',
        'php-curl',
        'php-mysql',
        'libfontconfig1-dev',     # For {systemfonts} R pkg dep of {hrbrthemes} pkg for dataviz (T254278)
        'libcairo2-dev',          # ^

        # For embedded configurable-http-proxy
        'nodejs',
        'npm',
        'libgslcblas0',
        'mariadb-client-10.3',
        'libyaml-cpp0.6',
        'libapache2-mod-python',
    ])
}
