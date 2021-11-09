class role::kerberos::kdc {
    include ::profile::base::production
    include ::profile::base::firewall

    system::role { 'kdc': description => 'Kerberos KDC' }

    include ::profile::kerberos::kdc
    include ::profile::kerberos::kadminserver
    include ::profile::kerberos::client
}
