# Class: tilerator
#
# This class installs and configures tilerator
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future tilerator needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
#
# === Parameters
#
# [*conf_sources*]
#   Sources that will be added to the configuration file of the service. This
#   defines the data transformation pipeline for the tile services. The actual
#   file is loaded from the root of the source code directory.
#   (/srv/deployment/tilerator/deploy/src/)
#   Default: 'sources.prod.yaml'
#
# [*contact_groups*]
#   Contact groups for alerting.
#   Default: 'admins'
#
# [*cassandra_servers*]
#   List of cassandra server names used by Tilerator
#
class tilerator(
    String $cassandra_pass,
    String $pgsql_pass,
    String $redis_server,
    String $redis_pass,
    Array[String] $cassandra_servers,
    String $storage_id,
    Integer[0] $num_workers,
    Boolean $enable,
    String  $contact_groups = 'admins',
    Boolean $use_nodejs10   = false,
) {

    $cassandra_user = 'tilerator'
    $pgsql_user = 'tilerator'
    $redis_url = "${redis_server}?password=${redis_pass}"

    # NOTE: The port here is only used for health monitoring. tilerator is a
    # daemon executing tasks from a queue, it does not realy listen to requests.
    # So there will never be LVS or anything else than health check requests to
    # this port
    service::node { 'tilerator':
        port              => 6534,
        deployment_config => true,
        no_workers        => $num_workers,
        deployment        => 'scap3',
        deployment_vars   => {
            entrypoint         => '""',
            cassandra_user     => $cassandra_user,
            cassandra_password => $cassandra_pass,
            cassandra_servers  => $cassandra_servers,
            osmdb_user         => $pgsql_user,
            osmdb_password     => $pgsql_pass,
            redis_server       => $redis_url,
            ui_only            => false,
            daemon_only        => true,
            storage_id         => $storage_id,
        },
        contact_groups    => $contact_groups,
        use_nodejs10      => $use_nodejs10,
        enable            => $enable,
    }

}
