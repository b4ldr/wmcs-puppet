# = Class: profile::iegreview
#
# This class provisions the IEG grant review application.
#
class profile::iegreview (
    Stdlib::Fqdn $iegreview_db_host = lookup('profile::iegreview::db_host'),
){

    class { '::iegreview':
        hostname   => 'iegreview.wikimedia.org',
        deploy_dir => '/srv/deployment/iegreview/iegreview',
        cache_dir  => '/var/cache/iegreview',
        # Send logs to udp2log relay
        log_dest   => 'udp://udplog.eqiad.wmnet:8420/iegreview',
        # Misc MySQL shard
        mysql_host => $iegreview_db_host,
        mysql_db   => 'iegreview',
        smtp_host  => 'localhost',
    }

    ensure_packages('mariadb-client')
}
# vim:sw=4 ts=4 sts=4 et:
