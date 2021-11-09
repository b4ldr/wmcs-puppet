class role::cache::upload {
    system::role { 'cache::upload':
        description => 'upload Varnish/ATS cache server',
    }

    include ::profile::base::production
    include ::profile::netconsole::client

    include ::profile::cache::base
    include ::profile::cache::varnish::frontend
    include ::profile::prometheus::varnish_exporter
    include ::profile::trafficserver::backend
    include ::profile::trafficserver::tls
}
