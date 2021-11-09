class role::durum {

    system::role { 'durum':
        description => 'Check service for Wikidough'
    }

    include profile::base::production
    include profile::base::firewall
    include profile::durum
    include profile::nginx
    include profile::bird::anycast

}
