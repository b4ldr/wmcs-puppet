# Placeholder define for single phase PDUs monitoring
# Also used to generate Prometheus targets/configuration

# See also https://phabricator.wikimedia.org/T229101
# and https://phabricator.wikimedia.org/T148541
define facilities::monitor_pdu_1phase(
    Stdlib::IP::Address $ip,
    String $row,
    String $site,
    Integer $breaker = 30,
    Boolean $redundant = true,
    String $model = 'sentry3',
    Hash[String, String] $mgmt_parents = lookup('monitoring::mgmt_parents'),  # lint:ignore:wmf_styleguide
) {

    @monitoring::host { $title:
        ip_address => $ip,
        group      => 'pdus',
        parents    => $mgmt_parents[$site],
    }

    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-single-phase":
        host      => $title,
        ip        => $ip,
        row       => $row,
        site      => $site,
        tower     => '1',
        infeed    => '1',
        breaker   => $breaker,
        redundant => $redundant,
        model     => $model,
    }

    if $redundant == true {
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-single-phase":
            host      => $title,
            ip        => $ip,
            row       => $row,
            site      => $site,
            tower     => '2',
            infeed    => '1',
            breaker   => $breaker,
            redundant => $redundant,
            model     => $model,
        }
    }
}
