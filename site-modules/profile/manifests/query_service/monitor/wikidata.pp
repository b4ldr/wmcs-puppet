# Monitor exteral blazegraph settings for the wikidata.org dataset
class profile::query_service::monitor::wikidata (
    String $username = lookup('profile::query_service::username'),
    String $contact_groups = lookup('contactgroups', {'default_value' => 'admins'}),
    Integer[0] $lag_warning = lookup('profile::query_service::lag_warning', {'default_value' => 1200}),
    Integer[0] $lag_critical = lookup('profile::query_service::lag_critical', {'default_value' => 3600}),
    Enum['regular', 'streaming'] $updater_type = lookup('profile::query_service::updater_type', {'default_value' => 'regular'})
) {
    nrpe::monitor_service { 'Query_Service_Internal_HTTP_endpoint':
        description  => 'Query Service HTTP Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
    }

    monitoring::service { 'WDQS_External_SPARQL_Endpoint':
        description   => 'WDQS SPARQL',
        check_command => 'check_https_url_for_string!query.wikidata.org!/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201!http://www.w3.org/2001/XMLSchema#dateTime',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }

    case $updater_type {
        'regular': {
            monitoring::check_prometheus { 'WDQS_Lag':
                description     => 'WDQS high update lag',
                dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/wikidata-query-service?orgId=1&panelId=8&fullscreen'],
                query           => "scalar(time() - blazegraph_lastupdated{instance=\"${::hostname}:9193\"})",
                prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
                warning         => $lag_warning,
                critical        => $lag_critical,
                contact_group   => $contact_groups,
                notes_link      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook#Update_lag',
            }
        }
        'streaming': {
            monitoring::check_prometheus { 'WDQS_Lag_Streaming':
                description     => 'WDQS high update lag',
                dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/wikidata-query-service?orgId=1&panelId=8&fullscreen'],
                query           => "scalar(wdqs_streaming_updater_kafka_stream_consumer_lag_Value{instance=\"${::hostname}:9101\"})",
                prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
                warning         => $lag_warning * 1000, # the metric is in ms
                critical        => $lag_critical * 1000, # the metric is in ms
                contact_group   => $contact_groups,
                notes_link      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook#Update_lag',
            }
        }
        default: { fail("Unsupported updater_type: ${updater_type}") }
    }
}
