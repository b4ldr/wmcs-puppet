# == Class profile::analytics::refinery::job::druid_load
#
# Installs spark jobs to load data sets to Druid.
#
class profile::analytics::refinery::job::druid_load(
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::druid_load::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::refinery

    # Update this when you want to change the version of the refinery job jar
    # being used for the druid load jobs.
    $refinery_version = '0.0.146'

    # Use this value as default refinery_job_jar.
    Profile::Analytics::Refinery::Job::Eventlogging_to_druid_job {
        ensure           => $ensure_timers,
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # Load event.EditAttemptStep
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'editattemptstep':
        job_config => {
            dimensions    => 'event.is_oversample,event.action,event.editor_interface,event.mw_version,event.platform,event.integration,event.page_ns,event.user_class,event.bucket,useragent.browser_family,useragent.browser_major,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,wiki,webhost',
        },
    }

    # Load event.NavigationTiming
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'navigationtiming':
        job_config => {
            dimensions    => 'event.action,event.isAnon,event.isOversample,event.mediaWikiVersion,event.mobileMode,event.namespaceId,event.netinfoEffectiveConnectionType,event.originCountry,recvFrom,revision,useragent.browser_family,useragent.browser_major,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,wiki',
            time_measures => 'event.connectEnd,event.connectStart,event.dnsLookup,event.domComplete,event.domInteractive,event.fetchStart,event.firstPaint,event.loadEventEnd,event.loadEventStart,event.redirecting,event.requestStart,event.responseEnd,event.responseStart,event.secureConnectionStart,event.unload,event.gaps,event.mediaWikiLoadEnd,event.RSI',
        },
    }

    # Load event.PageIssues
    # Deactivated for now until new experiment.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'pageissues':
        ensure     => 'absent',
        job_config => {
            dimensions => 'event.action,event.editCountBucket,event.isAnon,event.issuesSeverity,event.issuesVersion,event.namespaceId,event.sectionNumbers,revision,wiki,useragent.browser_family,useragent.browser_major,useragent.browser_minor,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,useragent.os_minor',
        },
    }

    # Load event.PrefUpdate
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'prefupdate':
        job_config => {
            dimensions => 'event.property,event.isDefault,wiki,useragent.browser_family,useragent.browser_major,useragent.browser_minor,useragent.device_family,useragent.os_family,useragent.os_major,useragent.os_minor'
        },
    }

    # Load wmf.netflow
    # Note that this data set does not belong to EventLogging, but the
    # eventlogging_to_druid_job wrapper is compatible and very convenient!
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'netflow':
        job_config        => {
            database         => 'event',
            druid_datasource => 'wmf_netflow',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'as_dst,as_path,peer_as_dst,as_src,ip_dst,ip_proto,ip_src,peer_as_src,port_dst,port_src,tag2,tcp_flags,country_ip_src,country_ip_dst,peer_ip_src,parsed_comms,net_cidr_src,net_cidr_dst,as_name_src,as_name_dst,ip_version,region',
            metrics          => 'bytes,packets',
        },
        # settings copied from webrequest_sampled_128 load job
        # as data-size is similar
        hourly_shards     => 4,
        hourly_reduce_mem => '8192',
        daily_shards      => 32,
    }
    # This second round serves as sanitization, after 90 days of data loading.
    # Note that some dimensions are not present, thus nullifying their values.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'netflow-sanitization':
        ensure_hourly    => 'absent',
        daily_days_since => 61,
        daily_days_until => 60,
        job_config       => {
            database         => 'event',
            table            => 'netflow',
            druid_datasource => 'wmf_netflow',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'as_dst,as_path,peer_as_dst,as_src,ip_proto,tag2,country_ip_src,country_ip_dst,parsed_comms,as_name_src,as_name_dst,ip_version,region',
            metrics          => 'bytes,packets',
        },
    }
}
