# == Class profile::hadoop::firewall::master
#
# Set of common firewall rules for Hadoop Master nodes (active and standby)
#
# == Parameters
# [*cluster_ferm_srange*]
#   Only hosts in this srange will be allowed to contact non-client related Hadoop master services.
#
# [*client_ferm_srrange*]
#   Hosts must be in this srange to contact Hadoop as a client.
#
class profile::hadoop::firewall::master(
    String $cluster_ferm_srange             = lookup('profile::hadoop::firewall::master::cluster_ferm_srange', {default_value => '$DOMAIN_NETWORKS'}),
    String $client_ferm_srange              = lookup('profile::hadoop::firewall::master::client_ferm_srange', {default_value => '$DOMAIN_NETWORKS'}),
    Boolean $hdfs_ssl_enabled               = lookup('profile::hadoop::firewall::master::hdfs::ssl_enabled', {default_value => false}),
    Boolean $yarn_ssl_enabled               = lookup('profile::hadoop::firewall::master::yarn::ssl_enabled', {default_value => false}),
    Boolean $mapred_ssl_enabled             = lookup('profile::hadoop::firewall::master::mapred::ssl_enabled', {default_value => false}),
    Optional[Integer] $hdfs_nn_service_port = lookup('profile::hadoop::firewall::master::hdfs_nn_service_port', {default_value => 8040}),
) {

    # This port is also used by the HDFS Checkpoint
    # workflow, as described in:
    # https://blog.cloudera.com/blog/2014/03/a-guide-to-checkpointing-in-hadoop/
    # If blocked it can lead to longer restarts for
    # the active NameNode (that needs to reply all the edit log
    # from its last old fsimage) and connect timeouts on the standby Namenode logs
    # (since it periodically tries to establish HTTPS connections).
    $hadoop_hdfs_namenode_http_port = $hdfs_ssl_enabled ? {
        true    => 50470,
        default => 50070,
    }

    $hadoop_yarn_resourcemanager_http_port = $yarn_ssl_enabled ? {
        true    => 8090,
        default => 8088,
    }

    $hadoop_mapreduce_historyserver_http_port = $mapred_ssl_enabled ? {
        true    => 19890,
        default => 19888,
    }

    ferm::service{ 'hadoop-hdfs-namenode':
        proto  => 'tcp',
        port   => '8020',
        srange => $client_ferm_srange,
    }

    if $hdfs_nn_service_port {
      ferm::service{ 'hadoop-hdfs-namenode-service':
          proto  => tcp,
          port   => $hdfs_nn_service_port,
          srange => $client_ferm_srange,

      }
    }

    ferm::service{ 'hadoop-hdfs-zkfc':
        proto  => 'tcp',
        port   => '8019',
        srange => $cluster_ferm_srange,
    }

    ferm::service{ 'hadoop-hdfs-namenode-http-ui':
        proto  => 'tcp',
        port   => $hadoop_hdfs_namenode_http_port,
        srange => $client_ferm_srange,
    }

    ferm::service{ 'hadoop-hdfs-namenode-jmx':
        proto  => 'tcp',
        port   => '9980',
        srange => $cluster_ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-scheduler':
        proto  => 'tcp',
        port   => '8030',
        srange => $cluster_ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-tracker':
        proto  => 'tcp',
        port   => '8031',
        srange => $cluster_ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager':
        proto  => 'tcp',
        port   => '8032',
        srange => $client_ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-admin':
        proto  => 'tcp',
        port   => '8033',
        srange => $cluster_ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-http-ui':
        proto  => 'tcp',
        port   => $hadoop_yarn_resourcemanager_http_port,
        srange => $client_ferm_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver':
        proto  => 'tcp',
        port   => '10020',
        srange => $client_ferm_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-admin':
        proto  => 'tcp',
        port   => '10033',
        srange => $cluster_ferm_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-http-ui':
        proto  => 'tcp',
        port   => $hadoop_mapreduce_historyserver_http_port,
        srange => $client_ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-jmx':
        proto  => 'tcp',
        port   => '9983',
        srange => $cluster_ferm_srange,
    }
}

