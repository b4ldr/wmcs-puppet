# Monitor single instance of Blazegraph
define  query_service::monitor::blazegraph_instance (
    Stdlib::Port $port,
    Stdlib::Port $prometheus_port,
    String $username,
    String $contact_groups,
) {
    nrpe::monitor_service { "Query_Service_Local_Blazegraph_endpoint-${title}":
        description  => "Blazegraph Port for ${title}",
        nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p ${port}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }

    nrpe::monitor_service { "${title}-_process":
        description  => "Blazegraph process (${title})",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ${username} --ereg-argument-array '^java .* --port ${port} .* blazegraph-service-.*war'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }

    monitoring::check_prometheus { "blazegraph_allocators_${title}":
        description     => "Free Blazegraph allocators ${title}",
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/wikidata-query-service?orgId=1&panelId=32&fullscreen'],
        query           => "blazegraph_free_allocators{instance=\"${::hostname}:${prometheus_port}\"}",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        method          => 'lt',
        warning         => 1000,
        critical        => 800,
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook'
    }

}
