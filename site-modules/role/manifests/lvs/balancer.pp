class role::lvs::balancer {
    system::role { 'lvs::balancer': description => 'LVS balancer' }

    include ::lvs::configuration
    include ::profile::base::production

    include ::profile::pybal
    include ::profile::lvs
    include ::profile::base::no_firewall
}
