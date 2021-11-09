# = Class: statistics::discovery
# Maintainer: Mikhail Popov (bearloga)
class statistics::discovery {
    Class['::statistics'] -> Class['::statistics::discovery']

    include ::passwords::mysql::research

    $working_path = $::statistics::working_path
    # Homedir for everything Search Platform (formerly Discovery) related
    $dir = "${working_path}/discovery"
    # Path in which daily runs will log to
    $log_dir = "${dir}/log"
    # Path in which the R library will reside
    $rlib_dir = "${dir}/r-library"

    $user = 'analytics-search'
    # Setting group to 'analytics-privatedata-users' so that Discovery's Analysts
    # (as members of analytics-privatedata-users) have some privileges, and so
    # the user can access private data in Hive. Also refer to T174110#4265908.
    $group ='analytics-privatedata-users'

    # This file will render at
    # /etc/mysql/conf.d/discovery-stats-client.cnf.
    ::mariadb::config::client { 'discovery-stats':
        ensure => 'absent',
        user   => $::passwords::mysql::research::user,
        pass   => $::passwords::mysql::research::pass,
        group  => $group,
        mode   => '0440',
    }

    $directories = [
        $dir,
        $log_dir,
        $rlib_dir
    ]

    file { $directories:
        ensure => 'absent',
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    git::clone { 'wikimedia/discovery/golden':
        ensure             => 'absent',
        branch             => 'master',
        recurse_submodules => true,
        directory          => "${dir}/golden",
        owner              => $user,
        group              => $group,
        require            => File[$dir],
    }

    # Assumes a virtual environment has been created as $dir/venv and that all
    # of reportupdater's dependencies have been installed in that environment.
    $systemd_env = {
        'PYTHONPATH' => "${dir}/venv/lib/python3.7/site-packages",
    }

    # Running the script at 5AM UTC means that:
    # - Remaining data from previous day is likely to have finished processing.
    # - It's ~9/10p Pacific time, so we're not likely to hinder people's work
    #   on analytics cluster, although we use `nice` & `ionice` as a courtesy.
    kerberos::systemd_timer { 'wikimedia-discovery-golden':
        ensure            => 'absent',
        description       => 'Discovery golden daily run',
        environment       => $systemd_env,
        command           => "${dir}/golden/main.sh",
        interval          => '*-*-* 05:00:00',
        user              => $user,
        logfile_basedir   => $log_dir,
        logfile_name      => 'golden-daily.log',
        logfile_owner     => $user,
        logfile_group     => $group,
        syslog_force_stop => true,
        slice             => 'user.slice',
        require           => [
            Class['::statistics::compute'],
            Git::Clone['wikimedia/discovery/golden'],
            Mariadb::Config::Client['discovery-stats']
        ],
    }
}
