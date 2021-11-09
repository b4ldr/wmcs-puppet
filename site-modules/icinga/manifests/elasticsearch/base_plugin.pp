# == Class icinga::elasticsearch::base_plugin
# Includes the nagios base checks for elasticsearch.
# include this class on your Nagios/Icinga node.
#
class icinga::elasticsearch::base_plugin {
    file {
        default:
            owner => 'root',
            group => 'root',
            mode  => '0755',
        ;
        '/usr/lib/nagios/plugins/check_elasticsearch':
            source => 'puppet:///modules/icinga/elasticsearch/check_elasticsearch',
        ;
        # new version, can do more fine-grained checks
        '/usr/lib/nagios/plugins/check_elasticsearch.py':
            source => 'puppet:///modules/icinga/elasticsearch/check_elasticsearch.py',
        ;
        '/usr/lib/nagios/plugins/check_elasticsearch_shard_size.py':
            source => 'puppet:///modules/icinga/elasticsearch/check_elasticsearch_shard_size.py',
        ;
        '/usr/lib/nagios/plugins/check_elasticsearch_unassigned_shards.py':
            source => 'puppet:///modules/icinga/elasticsearch/check_elasticsearch_unassigned_shards.py',
        ;
    }
    ensure_packages(['python3-requests', 'python3-dateutil'])
}
