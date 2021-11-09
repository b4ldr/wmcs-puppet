# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit {

    system::role { 'Gerrit': description => "Gerrit server in ${::realm}" }

    include ::profile::base::production
    include ::profile::backup::host
    include ::profile::base::firewall
    include ::passwords::gerrit
    include ::profile::gerrit
    include ::profile::gerrit::migration
    include ::profile::prometheus::apache_exporter
    include ::profile::java

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http', 'remoteip', 'ssl'],
    }
}
