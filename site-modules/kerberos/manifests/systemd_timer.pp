# == Define: kerberos::systemd_timer
#
# This used to be its own define, which got abstracted
# to the more general systemd::timer::job define.
# This is a wrapper to allow executing kinit before
# executing commands.
#
# [*description*]
#   Description to place in the systemd unit.
#
# [*command*]
#   Command to be executed periodically.
#
# [*interval*]
#   Systemd interval to use. Format: DayOfWeek Year-Month-Day Hour:Minute:Second
#
# [*user*]
#   User that runs the Systemd unit.
#   Default: 'analytics'
#
#  [*environment*]
#   Hash containing 'Environment=' related values to insert in the
#   Systemd unit.
#
#  [*monitoring_enabled*]
#   Periodically check the last execution of the unit and alarm if it ended
#   up in a failed state.
#   Default: true
#
#  [*monitoring_contact_groups*]
#   The monitoring's contact group to send the alarm to.
#   Default: analytics
#
#  [*logfile_basedir*]
#   Base directory where to store the syslog output of the
#   running unit.
#   Default: "/var/log/"
#
#  [*logfile_name*]
#   The filename of the file storing the syslog output of
#   the running unit. If set to undef, it avoids the deployment
#   of rsyslog/logrotate rules (relying only on journald).
#   Default: undef
#
#  [*logfile_owner*]
#   The user that owns the logfile.
#   Default: 'hdfs'
#
#  [*logfile_group*]
#   The group that owns the logfile.
#   Default: 'hdfs'
#
#  [*logfile_perms*]
#   The UNIX file permissions to set on the log file.
#   Check systemd::syslog for more info about the available options.
#   Default: 'all'
#
#  [*syslog_force_stop*]
#   Force logs to be written into the logfile but not in
#   syslog/daemon.log. This is particularly useful for units that
#   need to log a lot of information, since it prevents a duplication
#   of space consumed on disk.
#   Default: true
#
#  [*syslog_match_startswith*]
#   If true, all syslog programnames that start with the service_name
#   will be logged to the output log file.  Else, only service_names
#   that match exactly will be logged.
#   Default: true
#
#  [*syslog_identifier*]
#   Adds the SyslogIdentifier parameter to the systemd unit to
#   override the default behavior, namely using the program name.
#   This is particularly useful when multiple timers are scheduled
#   using the same program but with different parameters. Without
#   an explicit SyslogIdentifier in fact they would end up sharing
#   the same identifier and rsyslog rules wouldn't work anymore.
#   Default: undef
#
#  [*slice*]
#    Run the systemd timer's service unit under a specific slice.
#    By default the service unit will run under the system.slice.
#    Default: undef (do not add any Slice setting to the unit)
#
define kerberos::systemd_timer(
    $description,
    $command,
    $interval,
    $user = 'analytics',
    $environment = {},
    $monitoring_enabled = true,
    $monitoring_contact_groups = 'analytics',
    $logfile_basedir = '/var/log/',
    $logfile_name = undef,
    $logfile_owner = 'analytics',
    $logfile_group = 'analytics',
    $logfile_perms = 'all',
    $syslog_force_stop = true,
    $syslog_match_startswith = true,
    $syslog_identifier = undef,
    $ensure = present,
    Optional[Pattern[/\w+\.slice/]] $slice = undef,
) {

    require ::kerberos::wrapper

    # To ease testing in cloud/labs, there is a tunable that can be used
    # to skip the wrapper command and avoid the Kerberos authentication.
    if $::kerberos::wrapper::skip_wrapper {
        $wrapper = ''
    } else {
        $wrapper = "${kerberos::wrapper::kerberos_run_command_script} ${user} "
    }

    $logging = $logfile_name ? {
        undef   => false,
        default => true
    }
    systemd::timer::job { $title:
        ensure                    => $ensure,
        description               => $description,
        command                   => "${wrapper}${command}",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => $interval
        },
        user                      => $user,
        environment               => $environment,
        monitoring_enabled        => $monitoring_enabled,
        monitoring_contact_groups => $monitoring_contact_groups,
        logging_enabled           => $logging,
        logfile_basedir           => $logfile_basedir,
        logfile_name              => $logfile_name,
        logfile_owner             => $logfile_owner,
        logfile_group             => $logfile_group,
        logfile_perms             => $logfile_perms,
        syslog_identifier         => $syslog_identifier,
        syslog_match_startswith   => $syslog_match_startswith,
        syslog_force_stop         => $syslog_force_stop,
        slice                     => $slice,
    }
}
