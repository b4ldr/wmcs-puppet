# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::elasticsearch::logstash
    include ::profile::elasticsearch::monitor::base_checks
}
