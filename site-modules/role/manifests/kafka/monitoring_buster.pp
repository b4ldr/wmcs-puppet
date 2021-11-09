class role::kafka::monitoring_buster {

    system::role { 'kafka::monitoring_buster':
        description => 'Kafka consumer groups lag monitoring'
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::kafka::monitoring
}
