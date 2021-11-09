class profile::toolforge::k8s::haproxy (
    Array[
        Variant[
            Stdlib::Fqdn,
            Struct[{
                host      => Stdlib::Fqdn,
                port      => Optional[Stdlib::Port],
                jobs_port => Optional[Stdlib::Port],
            }]
        ]
    ]                   $ingress_nodes       = lookup('profile::toolforge::k8s::ingress_nodes',                {default_value => ['localhost']}),
    Stdlib::Port        $ingress_port        = lookup('profile::toolforge::k8s::ingress_port',                 {default_value => 30000}),
    Array[Stdlib::Fqdn] $control_nodes       = lookup('profile::toolforge::k8s::control_nodes',                {default_value => ['localhost']}),
    Stdlib::Port        $api_port            = lookup('profile::toolforge::k8s::apiserver_port',               {default_value => 6443}),
    Stdlib::Port        $jobs_port           = lookup('profile::toolforge::jobs_api_port',                     {default_value => 30001}),
    Array[Stdlib::Fqdn] $keepalived_vips     = lookup('profile::toolforge::k8s::haproxy::keepalived_vips',     {default_value => []}),
    Array[Stdlib::Fqdn] $keepalived_peers    = lookup('profile::toolforge::k8s::haproxy::keepalived_peers',    {default_value => ['localhost']}),
    String              $keepalived_password = lookup('profile::toolforge::k8s::haproxy::keepalived_password', {default_value => 'notarealpassword'}),
) {
    class { 'haproxy::cloud::base': }

    file { '/etc/haproxy/conf.d/k8s-api-servers.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-api-servers.cfg.erb'),
        notify  => Service['haproxy'],
    }
    file { '/etc/haproxy/conf.d/k8s-ingress.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/k8s-ingress-jobs.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress-jobs.cfg.erb'),
        notify  => Service['haproxy'],
    }

    class { 'prometheus::haproxy_exporter': }

    unless $keepalived_vips.empty {
        class { 'keepalived':
            auth_pass => $keepalived_password,
            peers     => delete($keepalived_peers, $::fqdn),
            vips      => $keepalived_vips.map |$host| { ipresolve($host, 4) },
        }
    }
}
