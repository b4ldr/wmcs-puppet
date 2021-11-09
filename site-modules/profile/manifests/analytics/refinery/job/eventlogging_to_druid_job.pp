# == Define profile::analytics::refinery::job::eventlogging_to_druid_job
#
# Installs crons to run HiveToDruid Spark jobs on EventLogging datasets.
# This job loads data from the given EL Hive table to a Druid datasource.
#
# We use spark's --files option to load each job's config file to the
# corresponding working HDFS dir. It will be then referenced via its relative
# file name with the --config_file option.
#
#
# TEMPORARY HACK
#
# The problem:
# HiveDruid does not use RefineTarget to determine which data pieces
# are available at a given moment and are to be loaded to Druid, because
# currently RefineTarget does not support Druid. Instead, HiveDruid
# just assumes that the passed date/time interval is correct and loads it
# without any check or filter. The interval checking needs to be done then by
# puppet (cron), passing a relative number of hours ago as since and until.
#
# Potential issues:
# 1) If the data pipeline is late for any reason (high load, outage, restarts,
#    etc.) HiveToDruid might not find the input data, or find it
#    incomplete, thus loading corrupt data to Druid for that hour.
# 2) If the cluster is busy and the HiveToDruid job takes more than
#    1 hour to launch (waiting), then 'since 6 hours ago' will skip 1 hour
#    (or more) and there will be a hole in the corresponding Druid datasource.
# This would cause user confusion, frustration and give the maintainers lots
# of work to manually backfill datasources.
#
# The right solution:
# We should improve RefineTarget to support Druid. However, this seems to be
# quite a bit of work. Task: https://phabricator.wikimedia.org/T207207
# But in the meantime...
#
# The temporary solution:
#
# Issue 1) Make this module install 2 loading jobs for each given datasource:
#    one hourly and one daily. The hourly one will load data as soon as
#    possible with the mentioned potential issues. The daily one, will load
#    data with a lag of 3-4 days (configurable), to automatically cover up any
#    hourly load issues that happened during that lag. A desirable side-effect
#    of this hack is that Druid hourly data gets compacted in daily segments.
#
# Issue 2) Instead of passing relative time offsets (hours ago), calculate
#    absolute timestamps for since and until using bash. To allow bash to
#    interpret date commands since and until params can not be passed via
#    config property file.
#
# == Properties
#
# [*job_config*]
#   A hash of job config properites that will be rendered as a properties file
#   and given to the HiveToDruid job as the --config_file argument.
#   Please, do not include the following properties: since, until,
#   segment_granularity, reduce_memory, num_shards. The reason being:
#   This profile will install 2 jobs for each datasource: hourly and daily.
#   Each of those will have different parameters for since, until, segment_
#   granularity, reduce_memory and num_shards. Therefore, those options are
#   specified inside this file.
#
# [*hourly_shards*]
#   Number of shards that the hourly segment of this datasource should have.
#   This will be usually 1, except for big schemas. Default: 1.
#
# [*hourly_reduce_mem*]
#   Reducer memory to allocate for hourly indexing job in hadoop.
#   This will be usually 4096, except for big schemas. Default: 4096.
#
# [*daily_shards*]
#   Number of shards that the daily segment of this datasource should have.
#   This will be usually 1, except for big schemas. Default: 1.
#
# [*daily_reduce_mem*]
#   Reducer memory to allocate for daily indexing job in hadoop.
#   This will be usually 8192, except for big schemas. Default: 8192.
#
# [*job_name*]
#   The Spark job name. Default: eventlogging_to_druid_$title
#
define profile::analytics::refinery::job::eventlogging_to_druid_job (
    $job_config,
    $hourly_shards       = 1,
    $hourly_reduce_mem   = '4096',
    $daily_shards        = 1,
    $daily_reduce_mem    = '8192',
    $job_name            = "eventlogging_to_druid_${title}",
    $refinery_job_jar    = undef,
    $job_class           = 'org.wikimedia.analytics.refinery.job.HiveToDruid',
    $queue               = 'production',
    $user                = 'analytics',
    $hourly_hours_since  = 6,
    $hourly_hours_until  = 5,
    $daily_days_since    = 4,
    $daily_days_until    = 3,
    $ensure_hourly       = 'present',
    $ensure_daily        = 'present',
    $ensure              = 'present',
    $deploy_mode         = 'client',
) {
    require ::profile::analytics::refinery
    $refinery_path = $profile::analytics::refinery::path

    # Override specific ensures, in case global ensure is absent.
    $_ensure_hourly = $ensure ? {
        'absent' => 'absent',
        default  => $ensure_hourly
    }
    $_ensure_daily = $ensure ? {
        'absent' => 'absent',
        default  => $ensure_daily
    }

    # If $refinery_job_jar not given, use the symlink at artifacts/refinery-job.jar
    $_refinery_job_jar = $refinery_job_jar ? {
        undef   => "${refinery_path}/artifacts/refinery-job.jar",
        default => $refinery_job_jar,
    }

    # Directory where HiveToDruid config property files will go
    $job_config_dir = "${::profile::analytics::refinery::config_dir}/eventlogging_to_druid"
    if !defined(File[$job_config_dir]) {
        file { $job_config_dir:
            ensure => 'directory',
        }
    }

    # Config options for all jobs, can be overriden by define params
    $default_config = {
        'database'            => 'event',
        'table'               => $title,
        'query_granularity'   => 'minute',
        'hadoop_queue'        => $queue,
        'druid_host'          => 'an-druid1001.eqiad.wmnet',
        'druid_port'          => '8090',
    }

    # Common Spark options for all jobs
    $default_spark_opts = "--master yarn --deploy-mode ${deploy_mode} --queue ${queue} --conf spark.driver.extraClassPath=/usr/lib/hive/lib/hive-jdbc.jar:/usr/lib/hadoop-mapreduce/hadoop-mapreduce-client-common.jar:/usr/lib/hive/lib/hive-service.jar"

    # Hourly job
    $hourly_job_config_file = "${job_config_dir}/${job_name}_hourly.properties"
    profile::analytics::refinery::job::config { $hourly_job_config_file:
        ensure     => $_ensure_hourly,
        properties => merge($default_config, $job_config, {
            'segment_granularity' => 'hour',
            'num_shards'          => $hourly_shards,
            'reduce_memory'       => $hourly_reduce_mem,
        }),
    }

    $config_file_path_hourly = $deploy_mode ? {
        'client' => $hourly_job_config_file,
        default  => "${job_name}_hourly.properties",
    }

    profile::analytics::refinery::job::spark_job { "${job_name}_hourly":
        ensure     => $_ensure_hourly,
        jar        => $_refinery_job_jar,
        class      => $job_class,
        spark_opts => "${default_spark_opts} --files /etc/hive/conf/hive-site.xml,${hourly_job_config_file} --conf spark.dynamicAllocation.maxExecutors=32 --driver-memory 2G",
        job_opts   => "--config_file ${config_file_path_hourly} --since $(date --date '-${hourly_hours_since}hours' -u +'%Y-%m-%dT%H:00:00') --until $(date --date '-${hourly_hours_until}hours' -u +'%Y-%m-%dT%H:00:00')",
        require    => Profile::Analytics::Refinery::Job::Config[$hourly_job_config_file],
        user       => $user,
        interval   => '*-*-* *:00:00',
    }

    # Daily job
    $daily_job_config_file = "${job_config_dir}/${job_name}_daily.properties"
    profile::analytics::refinery::job::config { $daily_job_config_file:
        ensure     => $_ensure_daily,
        properties => merge($default_config, $job_config, {
            'segment_granularity' => 'day',
            'num_shards'          => $daily_shards,
            'reduce_memory'       => $daily_reduce_mem,
        }),
    }

    $config_file_path_daily = $deploy_mode ? {
        'client' => $daily_job_config_file,
        default  => "${job_name}_daily.properties",
    }

    profile::analytics::refinery::job::spark_job { "${job_name}_daily":
        ensure     => $_ensure_daily,
        jar        => $_refinery_job_jar,
        class      => $job_class,
        spark_opts => "${default_spark_opts} --files /etc/hive/conf/hive-site.xml,${daily_job_config_file} --conf spark.dynamicAllocation.maxExecutors=64 --driver-memory 2G",
        job_opts   => "--config_file ${config_file_path_daily} --since $(date --date '-${daily_days_since}days' -u +'%Y-%m-%dT00:00:00') --until $(date --date '-${daily_days_until}days' -u +'%Y-%m-%dT00:00:00')",
        require    => Profile::Analytics::Refinery::Job::Config[$daily_job_config_file],
        user       => $user,
        interval   => '*-*-* 00:00:00',
    }
}
