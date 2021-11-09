# monitoring of https://www.mediawiki.org/wiki/ORES
class icinga::monitor::ores (
    String $icinga_user,
    String $icinga_group,
){

    @monitoring::host { 'ores.wikimedia.org':
        host_fqdn => 'ores.wikimedia.org',
    }

    monitoring::service { 'ores_main_page':
        ensure        => 'absent',
        description   => 'ORES home page',
        check_command => 'check_http',
        host          => 'ores.wmflabs.org',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

    $web_nodes = [ 'ores-web-04', 'ores-web-05', 'ores-web-06' ]

    icinga::monitor::ores_labs_web_node { $web_nodes: }

    # T121656
    monitoring::service { 'ores_worker_labs':
        ensure        => 'absent',
        description   => 'ORES worker labs',
        check_command => 'check_ores_workers!oresweb',
        host          => 'ores.wmflabs.org',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

    monitoring::service { 'ores_worker_production':
        description   => 'ORES worker production',
        check_command => 'check_ores_workers!ores.wikimedia.org',
        host          => 'ores.wikimedia.org',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

    # T122830
    file { '/usr/local/lib/nagios/plugins/check_ores_workers':
        source => 'puppet:///modules/nagios_common/check_commands/check_ores_workers',
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0550',
    }
}
