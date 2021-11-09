# Class: profile::hadoop::monitoring::datanode
#
# Sets up Prometheus based monitoring for the Hadoop HDFS Datanode.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::datanode(
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    String $hadoop_cluster_name           = lookup('profile::hadoop::common::hadoop_cluster_name'),
){

    $jmx_exporter_config_file = '/etc/prometheus/hdfs_datanode_jmx_exporter.yaml'
    $prometheus_jmx_exporter_datanode_port = 51010
    profile::prometheus::jmx_exporter { "hdfs_datanode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_datanode_port,
        prometheus_nodes => $prometheus_nodes,
        # Label these metrics with the hadoop cluster name.
        labels           => { 'hadoop_cluster' => $hadoop_cluster_name },
        config_file      => $jmx_exporter_config_file,
        config_dir       => '/etc/prometheus',
        source           => 'puppet:///modules/profile/hadoop/prometheus_hdfs_datanode_jmx_exporter.yaml',
    }
}
