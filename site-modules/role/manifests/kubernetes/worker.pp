class role::kubernetes::worker {
    include profile::base::production
    include profile::base::firewall
    include profile::base::linux419

    # Sets up docker on the machine
    include profile::docker::storage
    include profile::docker::engine
    # Setup dfdaemon and configure docker to use it
    include profile::dragonfly::dfdaemon
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Setup calico
    include profile::calico::kubernetes
    # Setup LVS
    include profile::lvs::realserver

    system::role { 'kubernetes::worker':
        description => 'Kubernetes worker node',
    }
}
