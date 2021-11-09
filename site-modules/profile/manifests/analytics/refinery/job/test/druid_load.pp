# == Class profile::analytics::refinery::job::druid_load
#
# Installs spark jobs to load data sets to Druid (only for testing)
#
class profile::analytics::refinery::job::test::druid_load {
    require ::profile::analytics::refinery

    # Update this when you want to change the version of the refinery job jar
    # being used for the druid load jobs.
    $refinery_version = '0.0.146'

    # Use this value as default refinery_job_jar.
    Profile::Analytics::Refinery::Job::Eventlogging_to_druid_job {
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar",
    }

    # Load event.NavigationTiming
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'navigationtiming':
        job_config   => {
            druid_host    => 'an-test-druid1001.eqiad.wmnet',
            dimensions    => 'event.action,event.isAnon,event.isOversample,event.mediaWikiVersion,event.mobileMode,event.namespaceId,event.netinfoEffectiveConnectionType,event.originCountry,recvFrom,revision,useragent.browser_family,useragent.browser_major,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,wiki',
            time_measures => 'event.connectEnd,event.connectStart,event.dnsLookup,event.domComplete,event.domInteractive,event.fetchStart,event.firstPaint,event.loadEventEnd,event.loadEventStart,event.redirecting,event.requestStart,event.responseEnd,event.responseStart,event.secureConnectionStart,event.unload,event.gaps,event.mediaWikiLoadEnd,event.RSI',
        },
    }
}
