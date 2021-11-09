# == Class role::aqs_next
# Analytics Query Service
#
# AQS is made up of a RESTBase instance backed by Cassandra.  Each AQS
# node has both colocated. aqs_next was created as a role used for AQS
# hosts running on buster with an updated version of Cassandra.
#
class role::aqs_next {
    system::role { 'aqs_next':
        description => 'Analytics Query Service Node - next generation',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::cassandra
    include ::profile::aqs

    include ::profile::rsyslog::udp_localhost_compat
    include profile::lvs::realserver
}
