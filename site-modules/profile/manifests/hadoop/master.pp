# == Class profile::hadoop::master
#
# Sets up a Hadoop Master node.
#
# == Parameters
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
#  [*use_kerberos*]
#    Force puppet to use kerberos authentication when executing
#    hdfs commands.
#
#  [*excluded_hosts*]
#    Hosts that are going to be added to the hosts.exclude
#    Default: []
#
class profile::hadoop::master(
    String $cluster_name        = lookup('profile::hadoop::common::hadoop_cluster_name'),
    Boolean $monitoring_enabled = lookup('profile::hadoop::master::monitoring_enabled', {'default_value' => false}),
    String $hadoop_user_groups  = lookup('profile::hadoop::master::hadoop_user_groups'),
    Boolean $use_kerberos       = lookup('profile::hadoop::master::use_kerberos', {'default_value' => false}),
    Array $excluded_hosts       = lookup('profile::hadoop::master::excluded_hosts', {'default_value' => []}),
){
    require ::profile::hadoop::common

    if $monitoring_enabled {
        # Prometheus exporters
        require ::profile::hadoop::monitoring::namenode
        require ::profile::hadoop::monitoring::resourcemanager
        require ::profile::hadoop::monitoring::history
    }

    class { '::bigtop::hadoop::master':
        excluded_hosts => $excluded_hosts,
    }

    # This will create HDFS user home directories
    # for all users in the provided groups.
    # This only needs to be run on the NameNode
    # where all users that want to use Hadoop
    # must have shell accounts anyway.
    class { '::bigtop::hadoop::users':
        groups  => $hadoop_user_groups,
        require => Class['bigtop::hadoop::master'],
    }

    # FairScheduler is creating event logs in hadoop.log.dir/fairscheduler/
    # It rotates them but does not delete old ones.  Set up cronjob to
    # delete old files in this directory.
    cron { 'hadoop-clean-fairscheduler-event-logs':
        command => 'test -d /var/log/hadoop-yarn/fairscheduler && /usr/bin/find /var/log/hadoop-yarn/fairscheduler -type f -mtime +14 -exec rm {} >/dev/null \;',
        minute  => 5,
        hour    => 0,
        require => Class['bigtop::hadoop::master'],
    }

    file { '/usr/local/lib/nagios/plugins/check_hdfs_topology':
        ensure => present,
        source => 'puppet:///modules/profile/hadoop/check_hdfs_topology',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        # Icinga process alerts for NameNode, ResourceManager and HistoryServer
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description   => 'Hadoop Namenode - Primary',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::master'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_Namenode_process',
        }
        nrpe::monitor_service { 'hadoop-hdfs-zkfc':
            description   => 'Hadoop HDFS Zookeeper failover controller',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.tools.DFSZKFailoverController"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::master'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_ZKFC_process',
        }
        nrpe::monitor_service { 'hadoop-yarn-resourcemanager':
            description   => 'Hadoop ResourceManager',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.resourcemanager.ResourceManager"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::master'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#Yarn_Resourcemanager_process',
        }
        nrpe::monitor_service { 'hadoop-mapreduce-historyserver':
            description   => 'Hadoop HistoryServer',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::master'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#Mapreduce_Historyserver_process',
        }

        if $use_kerberos {
            require ::profile::kerberos::client
            $kerberos_prefix = "${::profile::kerberos::client::run_command_script} hdfs "
            $nagios_kerberos_sudo_privileges = [
                "ALL = NOPASSWD: ${::profile::kerberos::client::run_command_script} hdfs /usr/local/bin/check_hdfs_active_namenode",
                "ALL = NOPASSWD: ${::profile::kerberos::client::run_command_script} hdfs /usr/local/lib/nagios/plugins/check_hdfs_topology"
            ]
        } else {
            $kerberos_prefix = ''
            $nagios_kerberos_sudo_privileges = []
        }

        $nagios_sudo_privileges = [
            'ALL = NOPASSWD: /usr/local/bin/check_hdfs_active_namenode',
            'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_hdfs_topology'
        ]

        # Allow nagios to run some scripts as hdfs user.
        sudo::user { 'nagios-check_hdfs_active_namenode':
            user       => 'nagios',
            privileges => $nagios_sudo_privileges + $nagios_kerberos_sudo_privileges,
        }

        # Alert if the HDFS topology shows any inconsistency.
        nrpe::monitor_service { 'check_hdfs_topology':
            description    => 'HDFS topology check',
            nrpe_command   => "/usr/bin/sudo ${kerberos_prefix}/usr/local/lib/nagios/plugins/check_hdfs_topology",
            check_interval => 30,
            retries        => 2,
            contact_group  => 'analytics',
            require        => File['/usr/local/lib/nagios/plugins/check_hdfs_topology'],
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_topology_check',
        }
        # Alert if there is no active NameNode
        nrpe::monitor_service { 'hadoop-hdfs-active-namenode':
            description   => 'At least one Hadoop HDFS NameNode is active',
            nrpe_command  => "/usr/bin/sudo ${kerberos_prefix}/usr/local/bin/check_hdfs_active_namenode",
            contact_group => 'analytics',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#No_active_HDFS_Namenode_running',
            require       => [
                Class['bigtop::hadoop::master'],
                Sudo::User['nagios-check_hdfs_active_namenode'],
            ],
        }

        # Alert in case of HDFS currupted or missing blocks. In the ideal state
        # these values should always be 0.
        monitoring::check_prometheus { 'hadoop-hdfs-corrupt-blocks':
            description     => 'HDFS corrupt blocks',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&orgId=1&panelId=39&fullscreen"],
            query           => "scalar(Hadoop_NameNode_CorruptBlocks{instance=\"${::hostname}:10080\"})",
            warning         => 30,
            critical        => 50,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_corrupt_blocks',
        }

        monitoring::check_prometheus { 'hadoop-hdfs-missing-blocks':
            description     => 'HDFS missing blocks',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&orgId=1&panelId=40&fullscreen"],
            query           => "scalar(Hadoop_NameNode_MissingBlocks{instance=\"${::hostname}:10080\"})",
            warning         => 2,
            critical        => 5,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_missing_blocks',
        }

        monitoring::check_prometheus { 'hadoop-hdfs-total-files-heap':
            description     => 'HDFS total files are more than what the heap size can support.',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&orgId=1&panelId=28&fullscreen"],
            query           => "scalar(Hadoop_NameNode_FilesTotal{instance=\"${::hostname}:10080\"})",
            warning         => 68000000,
            critical        => 70000000,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_total_files_and_heap_size',
        }

        monitoring::check_prometheus { 'hadoop-hdfs-rpc-queue-length':
            description     => 'HDFS Namenode RPC 8020 call queue length',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&orgId=1&panelId=54&fullscreen"],
            query           => "scalar(Hadoop_NameNode_CallQueueLength{name=\"RpcActivityForPort8020\", instance=\"${::hostname}:10080\"})",
            warning         => 10,
            critical        => 20,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_Namenode_RPC_length_queue',
        }

        monitoring::check_prometheus { 'hadoop-yarn-unhealthy-workers':
            description     => 'Yarn Nodemanagers in unhealthy status',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&orgId=1&panelId=46&fullscreen"],
            query           => "scalar(Hadoop_ResourceManager_NumUnhealthyNMs{instance=\"${::hostname}:10083\"})",
            warning         => 1,
            critical        => 3,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#Unhealthy_Yarn_Nodemanagers',
        }

        # Thresholds for the HDFS namenode are higher since it has always
        # filled most of its heap. This is not bad of course, but we'd like to know
        # if the usage stays above 90% over time to see if anything is happening.
        monitoring::check_prometheus { 'hadoop-hdfs-namenode-heap-usage':
            description     => 'HDFS active Namenode JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&panelId=4&fullscreen&orgId=1"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10080\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10080\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }

        monitoring::check_prometheus { 'hadoop-yarn-resourcemananager-heap-usage':
            description     => 'YARN active ResourceManager JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&panelId=12&fullscreen&orgId=1"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10083\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10083\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
    }
}
