# == Class elasticsearch::nagios::cirrus_plugin
# Includes the cirrus specific checks for elasticsearch.
# include this class on your Nagios/Icinga node.
#
class icinga::elasticsearch::cirrus_plugin {
    file {
        default:
            owner => 'root',
            group => 'root',
            mode  => '0755',
        ;
        '/usr/lib/nagios/plugins/check_cirrus_frozen_writes.py':
            source => 'puppet:///modules/icinga/elasticsearch/check_cirrus_frozen_writes.py',
        ;
        '/usr/lib/nagios/plugins/check_masters_eligible.py':
            source => 'puppet:///modules/icinga/elasticsearch/check_masters_eligible.py',
        ;
    }
    ensure_packages(['python3-requests', 'python3-dateutil'])
}
