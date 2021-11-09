# vim: set ts=4 et sw=4:
# sets up an instance of the 'Open-source Ticket Request System'
# https://en.wikipedia.org/wiki/OTRS
#
class role::otrs {
    system::role { 'otrs':
        description => 'OTRS Web Application Server',
    }
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::otrs
    include ::profile::tlsproxy::envoy # TLS termination
}
