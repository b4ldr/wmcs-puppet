# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    Hash[String, Hash] $kubernetes_cluster_groups                      = lookup('kubernetes_cluster_groups'),
    Profile::Kubernetes::User_defaults $user_defaults                  = lookup('profile::kubernetes::deployment_server::user_defaults'),
    Hash[String, Hash[String,Profile::Kubernetes::Services]] $services = lookup('profile::kubernetes::deployment_server::services', {default_value => {}}),
    Hash[String, Hash[String, Hash]] $tokens                           = lookup('profile::kubernetes::infrastructure_users', {default_value => {}}),
    Boolean $packages_from_future                                      = lookup('profile::kubernetes::deployment_server::packages_from_future', {default_value => false}),
    Boolean $include_admin                                             = lookup('profile::kubernetes::deployment_server::include_admin', {default_value => false}),
){
    include profile::kubernetes::deployment_server::helmfile
    include profile::kubernetes::deployment_server::mediawiki
    class { '::helm': }
    class { '::k8s::client':
        packages_from_future => $packages_from_future,
    }

    ensure_packages('istioctl')

    # For each cluster group, then for each cluster, we gather
    # the list of services, and the corresponding tokens, then we build
    # the kubeconfigs for all of them.
    $kubernetes_cluster_groups.map |$cluster_group, $clusters| {
        $_tokens = $tokens[$cluster_group]
        $_services = pick($services[$cluster_group], {})
        # for each service installed on the cluster group,
        # cycle through all clusters to define their kubeconfigs.
        $_services.each |$srv, $data| {
            # If the namespace is undefined, use the service name.
            $namespace = $data['namespace'] ? {
                undef   => $srv,
                default => $data['namespace']
            }
            $clusters.each |$cluster, $cluster_data| {
                $data['usernames'].each |$usr_raw| {
                    $usr = $user_defaults.merge($usr_raw)
                    $token = $_tokens[$usr['name']]
                    # Allow overriding the kubeconfig name
                    $kubeconfig_name = $usr['kubeconfig'] ? {
                        undef => $usr['name'],
                        default => $usr['kubeconfig']
                    }
                    $kubeconfig_path = "/etc/kubernetes/${kubeconfig_name}-${cluster}.config"
                    # TODO: separate username data from the services structure?
                    if ($token and !defined(K8s::Kubeconfig[$kubeconfig_path])) {
                        k8s::kubeconfig{ $kubeconfig_path:
                            master_host => $cluster_data['master'],
                            username    => $usr['name'],
                            token       => $token['token'],
                            owner       => $usr['owner'],
                            group       => $usr['group'],
                            mode        => $usr['mode'],
                            namespace   => $namespace,
                        }
                    }
                }
            }
        }
        # Now if we're including the admin account, add it for every cluster in the cluster
        # group.
        if $include_admin {
            $clusters.each |$cluster, $cluster_data| {
                k8s::kubeconfig { "/etc/kubernetes/admin-${cluster}.config":
                    master_host => $cluster_data['master'],
                    username    => 'client-infrastructure',
                    token       => $_tokens['client-infrastructure']['token'],
                    group       => 'root',
                    owner       => 'root',
                    mode        => '0400'
                }
            }
        }
    }


    $kube_env_services_base = $include_admin ? {
        true  => ['admin'],
        false => []
    }
    # Used to support the kube-env.sh script. A list of service names is useful
    # to create an auto-complete feature for kube_env.
    # Please note: here we're using the service names because we assume there is a user with that name
    # If not, the service will break down the assumptions kube_env does and should not be included.
    $kube_env_services = $kube_env_services_base + $services.map |$_, $srvs| {
        # Filter out services that don't have a username
        keys($srvs).filter |$svc_name| { $svc_name in $srvs[$svc_name]['usernames'].map |$u| {$u['name']}}
    }.flatten().unique()
    $kube_env_environments = $kubernetes_cluster_groups.map |$_, $clusters| {
        keys($clusters)
    }.flatten().unique()
    # Add a script to profile.d with functions to set the configuration for kubernetes.
    file { '/etc/profile.d/kube-env.sh':
        ensure  => present,
        content => template('profile/kubernetes/kube-env.sh.erb'),
        mode    => '0555',
    }
}
