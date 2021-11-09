class role::dragonfly::supernode {
    include profile::base::production
    include profile::base::firewall

    include profile::dragonfly::supernode

    system::role { 'dragonfly::supernode':
        description => 'Dragonfly Supernode',
    }
}
