class role::dumps::distribution::server {
    system::role { 'dumps::distribution::server': description => 'labstore host in the public VLAN that distributes Dumps to clients via NFS/Web/Rsync' }

    include profile::base::production
    include profile::base::firewall
    include profile::wmcs::nfs::ferm
    include profile::nginx
    # For downloading public datasets from HDFS analytics-hadoop.
    include profile::java
    include profile::hadoop::common
    include profile::analytics::cluster::hdfs_mount

    include profile::dumps::distribution::server
    include profile::dumps::distribution::nfs
    include profile::dumps::distribution::rsync
    include profile::dumps::distribution::ferm
    include profile::dumps::distribution::web
    include profile::dumps::distribution::monitoring

    include profile::dumps::distribution::datasets::cleanup
    include profile::dumps::distribution::datasets::dumpstatusfiles_sync
    include profile::dumps::distribution::datasets::rsync_config
    include profile::dumps::distribution::datasets::fetcher
    include profile::dumps::distribution::datasets::enterprise

    include profile::dumps::distribution::mirrors::rsync_config

    # Deploy some Analytics tools to ease pulling data from Hadoop
    include profile::analytics::hdfs_tools

    # Kerberos client and credentials to fetch data from
    # the Analytics Hadoop cluster.
    include profile::kerberos::client
    include profile::kerberos::keytabs

}
