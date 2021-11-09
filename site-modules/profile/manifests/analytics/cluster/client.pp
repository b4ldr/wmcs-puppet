# == Class profile::analytic::cluster::client
#
# Includes common client classes for working
# with hadoop and other Analytics Cluster services.
#
class profile::analytics::cluster::client {
    require ::profile::analytics::cluster::packages::common

    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client
    require ::profile::oozie::client

    # This is a Hadoop client, and should
    # have any service system users it needs to
    # interacting with HDFS.
    include ::profile::analytics::cluster::users

    # Spark 2 is manually packaged by us, it is not part of CDH.
    require ::profile::hadoop::spark2

    # These don't require any extra configuration,
    # so no role class is needed.
    class { '::bigtop::sqoop': }
    class { '::bigtop::mahout': }

    include ::profile::analytics::hdfs_tools
    include ::profile::analytics::cluster::hdfs_mount

    # Install other useful packages for client nodes.
    # Packages that should exist on both clients and workers
    # belong in the profile::analytics::cluster::packages::common class.
    ensure_packages([
        'kafkacat',
        'jupyter-notebook',
        's-nail',
    ])
}
