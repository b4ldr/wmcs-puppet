# == Class profile::hive::site_hdfs
#
# Ensures latest /etc/hive/conf/hive-site.xml is in hdfs
#
# TODO: it would be much better if we had a nicer define or puppet function
# that would allow us to manage files in HDFS like we do in the regular
# filesystem.  If we figure that out, we can replace this class and also
# the analytics_cluster::mysql_password class.
#
class profile::hive::site_hdfs {
    Class['bigtop::hive'] -> Class['profile::hive::site_hdfs']

    $hdfs_path = '/user/hive/hive-site.xml'
    # Put /etc/hive/conf/hive-site.xml in HDFS whenever puppet
    # notices that it has changed.
    kerberos::exec { 'put-hive-site-in-hdfs':
        command     => "/bin/bash -c '/usr/bin/hdfs dfs -put -f ${bigtop::hive::config_directory}/hive-site.xml ${hdfs_path} && /usr/bin/hdfs dfs -chmod 664 ${hdfs_path} && /usr/bin/hdfs dfs -chown hive:analytics ${hdfs_path}'",
        user        => 'hdfs',
        refreshonly => true,
        subscribe   => File["${bigtop::hive::config_directory}/hive-site.xml"],
    }
}
