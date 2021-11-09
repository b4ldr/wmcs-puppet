# == Class: parsoid
#
# Parsoid is a wt2HTML and HTML2wt parser able to deliver no-diff round-trip
# conversions between the two formats.
#
# === Parameters
#
# [*port*]
#   Port to run the Parsoid service on. Default: 8000
#
# [*conf*]
#   Hash or YAML-formatted string that gets merged into the service's
#   configuration.  Only applicable for non-scap3 deployments.
#
# [*no_workers*]
#   Number of http workers to start.  Default: 'ncpu' (i.e. start as many
#   workers as there are CPUs)  The same meaning as in service::node
#   Only applicable for non-scap3 deployments.
#
# [*logging_name*]
#   The logging name to send to logstash. Default: 'parsoid'
#
# [*statsd_prefix*]
#   The statsd metric prefix to use. Default: 'parsoid'
#
# [*deployment*]
#   Deployment system to use: available are trebuchet, scap3 or git.
#   Default: scap3
#
# [*mwapi_server*]
#   The full URI of the MW API endpoint to contact when issuing direct
#   requests to it. Default: ''
#
# [*mwapi_proxy*]
#   The proxy to use to contact the MW API. Note that you usually want to set
#   either mwapi_server or this variable. Do not set both! Default:
#   'http://api.svc.eqiad.wmnet'
class parsoid(
    Stdlib::Port $port = 8000,
    Optional[Variant[Hash,String]]$conf = undef,
    Variant[Integer, Enum['ncpu']] $no_workers = 'ncpu',
    String $logging_name = 'parsoid',
    String $statsd_prefix = 'parsoid',
    String $deployment = 'scap3',
    Optional[Stdlib::Httpurl] $mwapi_server = undef,
    Variant[Stdlib::Httpurl, Enum['']] $mwapi_proxy = 'http://api.svc.eqiad.wmnet',
    Optional[String] $discovery = undef,
){

    service::node { 'parsoid':
        port              => $port,
        starter_script    => 'src/bin/server.js',
        healthcheck_url   => '/',
        has_spec          => false,
        logging_name      => $logging_name,
        auto_refresh      => false,
        deployment        => $deployment,
        deployment_config => false,
        full_config       => 'external',
    }


    if ($deployment == 'scap3') {
        $deployment_vars = {
            mwapi_server => $mwapi_server,
            mwapi_proxy  => $mwapi_proxy,
        }

        service::node::config::scap3 { 'parsoid':
            port            => $port,
            starter_module  => 'src/lib/index.js',
            entrypoint      => 'apiServiceWorker',
            logging_name    => $logging_name,
            heap_limit      => 800,
            heartbeat_to    => 180000,
            statsd_prefix   => $statsd_prefix,
            auto_refresh    => false,
            deployment_vars => $deployment_vars,
        }
    } else {
        service::node::config { 'parsoid':
            port           => $port,
            config         => $conf,
            no_workers     => $no_workers,
            starter_module => 'src/lib/index.js',
            entrypoint     => 'apiServiceWorker',
            logging_name   => $logging_name,
            heap_limit     => 800,
            heartbeat_to   => 180000,
            statsd_prefix  => $statsd_prefix,
            auto_refresh   => false,
        }
    }
}
