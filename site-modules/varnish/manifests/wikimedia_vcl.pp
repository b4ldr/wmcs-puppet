define varnish::wikimedia_vcl(
    $varnish_testing = false,
    $template_path = '',
    $vcl_config = {},
    $backend_caches = [],
    $backend_options = {},
    $dynamic_backend_caches = true,
    $vcl = '',
    $generate_extra_vcl = false,
    $is_separate_vcl=false,
    $wikimedia_nets=[],
    $wikimedia_trust=[],
) {
    if $varnish_testing  {
        $netmapper_dir = '/usr/share/varnish/tests'
    } else {
        $netmapper_dir = '/var/netmapper'
    }

    # Hieradata switch to shut users out of a DC/cluster. T129424
    $traffic_shutdown = lookup('cache::traffic_shutdown', {'default_value' => false})

    if $generate_extra_vcl {
        $extra_vcl_name = regsubst($title, '^([^ ]+) .*$', '\1')
        $extra_vcl_filename = "/etc/varnish/${extra_vcl_name}.inc.vcl"
        if !defined(File[$extra_vcl_filename]) {
            file { $extra_vcl_filename:
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template("varnish/${extra_vcl_name}.inc.vcl.erb"),
            }
        }
    } else {
        file { $title:
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template($template_path),
            notify  => $notify,
            require => $require,
            before  => $before,
        }
    }
}
