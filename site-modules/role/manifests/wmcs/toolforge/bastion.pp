class role::wmcs::toolforge::bastion {
    system::role { $name:
        description => 'Toolforge bastion'
    }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::grid::base
    include profile::toolforge::grid::submit_host
    include profile::toolforge::grid::sysctl
    include profile::toolforge::bastion
    include profile::toolforge::bastion::resourcecontrol
    include profile::wmcs::dologmsg
}
