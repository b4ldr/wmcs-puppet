# == Class profile::discovery::client
#
# Will use confd to watch our discovery system and save the result as a json file in a chosen directory.
#
# === Parameters
#
# [*path*] The directory where the file should go.
#
# [*watch_interval*] The interval in seconds for checks on etcd. Defaults to 5
#
class profile::discovery::client(
    Stdlib::Unixpath $path=lookup('profile::discovery::path'),
){
    # We need confd
    require ::profile::conftool::state
    file { $path:
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    confd::file { "${path}/discovery-basic.yaml":
        ensure     => present,
        content    => template('profile/discovery/basic.yaml.tpl.erb'),
        watch_keys => ['/'],
        prefix     => '/discovery',
        mode       => '0444',
        check      => 'ruby -e \"require \'yaml\'; YAML.load_file(\'{{ .src }}\')\"',
    }

    confd::file { "${path}/services.yaml":
        ensure     => absent,
    }
}
