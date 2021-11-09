# == Class: role::webperf::processors_and_site
#
class role::webperf::processors_and_site {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::webperf::processors
    include ::profile::webperf::coal_web
    include ::profile::webperf::site
    include ::profile::tlsproxy::envoy # TLS termination

    system::role { 'webperf::processors_and_site':
        description => 'performance team data processor and performance.wikimedia.org server'
    }

    class { '::httpd':
        modules   => ['uwsgi', 'proxy', 'proxy_http', 'headers', 'ssl'],
        http_only => true,
    }
}
