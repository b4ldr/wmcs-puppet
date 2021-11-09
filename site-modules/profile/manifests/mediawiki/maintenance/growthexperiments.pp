class profile::mediawiki::maintenance::growthexperiments {
    # Purge old welcome survey data (personal data used in user options,
    # with 90-day retention) that's within 30 days of expiry, twice a month.
    # See T208369 and T252575. Logs are saved to
    # /var/log/mediawiki/mediawiki_job_growthexperiments-deleteOldSurveys/syslog.log
    profile::mediawiki::periodic_job { 'growthexperiments-deleteOldSurveys':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/deleteOldSurveys.php --cutoff 60',
        interval => '*-*-01,15 03:15:00',
    }

    # Ensure that a sufficiently large pool of link recommendations is available.
    profile::mediawiki::maintenance::growthexperiments::refreshlinkrecommendations { [ 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8' ]: }

    # Track link recommendation pool size
    profile::mediawiki::periodic_job { 'growthexperiments-listTaskCounts':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/listTaskCounts.php --tasktype link-recommendation --topictype ores --statsd --output none',
        interval => '*-*-* *:11:00',
    }

    # update data for the mentor dashboard (T285811)
    profile::mediawiki::maintenance::growthexperiments::updatementeedata { [ 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8' ]: }

    # monitor dangling link recommendation entries (DB record without search index record or vice versa)
    profile::mediawiki::periodic_job { 'growthexperiments-fixLinkRecommendationData-dryrun':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/fixLinkRecommendationData.php --search-index --db-table --dry-run --statsd',
        interval => '*-*-* 07:20:00',
    }

    # purge expired rows from the database (Mentor dashboard, T280307)
    profile::mediawiki::periodic_job { 'growthexperiments-purgeExpiredMentorStatus':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/purgeExpiredMentorStatus.php',
        interval => '*-*-01,15 8:45:00',
    }
}
