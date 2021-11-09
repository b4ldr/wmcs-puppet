class kubeadm::calico_workaround (
) {
    require ::kubeadm::core   # because kubeadm package
    require ::kubeadm::docker # because docker-ce package

    # we require this in Buster because calico hardcodes iptables-legacy
    # calls, but otherwise it could work with the nf_tables backend.
    # We could pretty much do this the other way around: hack calico into
    # using iptables-nft (requires iptables 1.8.3)
    debian::codename::require('buster')

    alternatives::select { 'iptables':
        path    => '/usr/sbin/iptables-legacy',
        require => Package['docker-ce'], # iptables is a docker-ce depedency
    }
    alternatives::select { 'ip6tables':
        path    => '/usr/sbin/ip6tables-legacy',
        require => Package['docker-ce'], # iptables is a docker-ce dependency
    }
    alternatives::select { 'ebtables':
        path    => '/usr/sbin/ebtables-legacy',
        require => Package['kubeadm'],   # ebtables is a kubelet dependency, which is a kubeadm dep
    }
}
