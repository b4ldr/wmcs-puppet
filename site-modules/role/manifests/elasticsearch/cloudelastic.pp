# = Class: role::elasticsearch::cloudelastic
#
# This class sets up Elasticsearch specifically for CirrusSearch on cloudelastic nodes.
#
class role::elasticsearch::cloudelastic {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::elasticsearch::cirrus
    include ::profile::elasticsearch::monitor::base_checks
    include ::profile::lvs::realserver

    system::role { 'elasticsearch::cloudelastic':
        ensure      => 'present',
        description => 'elasticsearch cloud elastic cirrus',
    }
}
