# @summary configure host to be a docker based GitLab runner
# @param ensure Ensure of the resources that support it
# @param access_level Whether the runner is protected or not. Whenever a runner is protected, it
# picks only jobs created on protected branches or protected tags, and ignores other jobs.
# @param concurrent Number of concurrent jobs allowed by this runner.
# @param docker_image Default Docker image to use for job execution
# @param docker_volume Use a separate volume for docker data (for use on WMCS)
# @param docker_volume_min Minimum size (Gb) of attached volumes considered for the docker mount.
# @param docker_volume_max Maximum size (Gb) of attached volumes considered for the docker mount.
# @param docker_settings Docker daemon settings
# @param docker_version Version of Docker to install
# @param gitlab_url URL of the GitLab instance on which to register
# @param locked Whether the runner is locked and can/cannot be enabled for projects
# @param registration_token Token used to register the runner with the GitLab instance.
# @param run_untagged Whether the runner should also run untagged jobs
# @param tags Tags used to schedule matching jobs to this runner
class profile::gitlab::runner (
    Wmflib::Ensure                         $ensure             = lookup('profile::gitlab::runner::ensure'),
    Enum['not_protected', 'ref_protected'] $access_level       = lookup('profile::gitlab::runner::access_level'),
    Integer                                $concurrent         = lookup('profile::gitlab::runner::concurrent'),
    String                                 $docker_image       = lookup('profile::gitlab::runner::docker_image'),
    Boolean                                $docker_volume      = lookup('profile::gitlab::runner::docker_volume'),
    Integer                                $docker_volume_min  = lookup('profile::gitlab::runner::docker_volume_min'),
    Integer                                $docker_volume_max  = lookup('profile::gitlab::runner::docker_volume_max'),
    Hash                                   $docker_settings    = lookup('profile::gitlab::runner::docker_settings'),
    String                                 $docker_version     = lookup('profile::gitlab::runner::docker_version'),
    Stdlib::HTTPSUrl                       $gitlab_url         = lookup('profile::gitlab::runner::gitlab_url'),
    Boolean                                $locked             = lookup('profile::gitlab::runner::locked'),
    String                                 $registration_token = lookup('profile::gitlab::runner::registration_token'),
    Boolean                                $run_untagged       = lookup('profile::gitlab::runner::run_untagged'),
    Array[String]                          $tags               = lookup('profile::gitlab::runner::tags'),
) {
    class { 'docker::configuration':
        settings => $docker_settings,
    }

    class { 'docker':
        package_name => 'docker.io',
        version      => $docker_version,
    }

    if $docker_volume {
        cinderutils::ensure { '/var/lib/docker':
            min_gb        => $docker_volume_min,
            max_gb        => $docker_volume_max,
            mount_point   => '/var/lib/docker',
            mount_mode    => '711',
            mount_options => 'discard,defaults',
            before        => Class['docker'],
        }
    }

    ferm::conf { 'docker-ferm':
        ensure => $ensure,
        prio   => 20,
        source => 'puppet:///modules/profile/ci/docker-ferm',
    }

    apt::package_from_component{ 'gitlab-runner':
        component => 'thirdparty/gitlab-runner',
        require   =>  Class['docker'],
    }

    $runner_name = "${::hostname}.${::domain}"

    if $ensure == 'present' {
        $tag_list = join($tags, ',')

        exec { 'gitlab-register-runner':
            user    => 'root',
            command => @("CMD"/L$)
                /usr/bin/gitlab-runner register \
                --non-interactive \
                --name "${runner_name}" \
                --url "${gitlab_url}" \
                --registration-token "${registration_token}" \
                --executor "docker" \
                --docker-image "${docker_image}" \
                --tag-list "${tag_list}" \
                --run-untagged="${run_untagged}" \
                --locked="${locked}" \
                --access-level="${access_level}"
                |- CMD
            ,
            unless  => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name} '",
            require => Apt::Package_from_component['gitlab-runner'],
        }

        # Believe it or not, there's no CLI for modifying the global
        # concurrent setting.
        # See https://gitlab.com/gitlab-org/gitlab-runner/-/issues/1539
        file_line { 'gitlab-runner-config-concurrent':
            path    => '/etc/gitlab-runner/config.toml',
            match   => '^concurrent *=',
            line    => "concurrent = ${concurrent}",
            require => Exec['gitlab-register-runner'],
            notify  => Exec['gitlab-runner-restart'],
        }

        exec { 'gitlab-runner-restart':
            user        => 'root',
            command     => '/usr/bin/gitlab-runner restart',
            refreshonly =>  true,
        }
    } else {
        exec { 'gitlab-unregister-runner':
            user    => 'root',
            command => "/usr/bin/gitlab-runner unregister --name '${runner_name}'",
            onlyif  => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name} '",
            before  =>  Package['gitlab-runner'],
        }
    }
}
