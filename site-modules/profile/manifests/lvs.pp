# === Class profile::lvs
#
# Sets up a linux load-balancer.
#
class profile::lvs(
    Array[String] $tagged_subnets = lookup('profile::lvs::tagged_subnets'),
    Hash[String, Hash] $vlan_data = lookup('lvs::interfaces::vlan_data'),
    Hash[String, Hash] $interface_tweaks = lookup('profile::lvs::interface_tweaks'),
){
    require ::lvs::configuration

    $services = wmflib::service::get_services_for_lvs($::lvs::configuration::lvs_class, $::site)

    ## Kernel setup

    # defaults to "performance"
    class { '::cpufrequtils': }

    # kernel-level parameters
    class { '::lvs::kernel_config': }

    ## LVS IPs setup
    # Obtain all the IPs configured for this class of load-balancers,
    # as an array.
    $service_ips = wmflib::service::get_ips_for_services($services, $::site)

    # Bind balancer IPs to the loopback interface
    class { '::lvs::realserver':
        realserver_ips => $service_ips
    }

    # Monitoring sysctl
    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub(/[_:.]/,"/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/lib/nagios/plugins/check_sysctl ${rp_args}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_rp_filter_disabled',
    }

    monitoring::check_prometheus { 'excessive-lvs-rx-traffic':
        description     => 'Excessive RX traffic on an LVS (units megabits/sec)',
        warning         => 1600,
        critical        => 3200,
        query           => "scalar(sum(rate(node_network_receive_bytes_total{instance=~\"${::hostname}:.*\",device\\!~\"lo\"}[5m]))) * 8 / 1024 / 1024",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://bit.ly/wmf-lvsrx',
        dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        nagios_critical => true,
    }

    monitoring::check_prometheus { 'lvs-cpu-saturated':
        description     => 'At least one CPU core of an LVS is saturated, packet drops are likely',
        warning         => 0.35,  # Unit: core-busy-seconds/second
        critical        => 0.7,
        query           => "sum by (cpu) (irate(node_cpu_seconds_total{mode\\!=\"idle\",instance=~\"${::hostname}:.*\"}[5m]))",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://bit.ly/wmf-lvscpu',
        dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        nagios_critical => false,  # TODO set this to true Soon
    }

    # Set up tagged interfaces to all subnets with real servers in them

    profile::lvs::tagged_interface {$tagged_subnets:
        interfaces => $vlan_data
    }

    # Apply needed interface tweaks

    create_resources(profile::lvs::interface_tweaks, $interface_tweaks)

}
