class varnish::common::vcl($vcl_config={}) {
    require varnish::common
    require varnish::common::errorpage
    require varnish::common::browsersec

    file { '/etc/varnish/translation-engine.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/translation-engine.inc.vcl.erb'),
    }

    file { '/etc/varnish/analytics.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/analytics.inc.vcl.erb'),
    }

    file { '/etc/varnish/alternate-domains.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/alternate-domains.inc.vcl.erb'),
    }

    # ACL blocked_nets is defined in hiera in the private puppet repo under
    # /srv/private/hieradata/common.yaml
    $abuse_networks = network::parse_abuse_nets('varnish')
    file { '/etc/varnish/blocked-nets.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/blocked-nets.inc.vcl.erb'),
    }

    # Directory with test versions of VCL files to run VTC tests
    file { '/usr/share/varnish/tests':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
