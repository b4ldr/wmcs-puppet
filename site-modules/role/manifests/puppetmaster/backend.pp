# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::puppetmaster::backend

    require ::profile::conftool::client
    # This profile is needed for puppet to access state stored in etcd
    require ::profile::conftool::state

}
