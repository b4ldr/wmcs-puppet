#
class profile::rsyslog::kubernetes (
    Boolean $enable = lookup(
        'profile::rsyslog::kubernetes::enable', {'default_value' => false}),
    Optional[String] $token = lookup(
        'profile::rsyslog::kubernetes::token', {'default_value' => undef}),
    Optional[Stdlib::HTTPSUrl] $kubernetes_url = lookup(
        'profile::rsyslog::kubernetes::kubernetes_url', {'default_value' => undef}),
) {

    if debian::codename::eq('buster') {
        apt::package_from_component { 'rsyslog_kubernetes':
            component => 'component/rsyslog-k8s',
            packages  => ['rsyslog-kubernetes'],
        }
    } else {
        ensure_packages('rsyslog-kubernetes')
    }

    $ensure = $enable ? {
      true    => present,
      default => absent,
    }

    rsyslog::conf { 'kubernetes':
        ensure   => $ensure,
        content  => template('profile/rsyslog/kubernetes.conf.erb'),
        priority => 9,
        mode     => '0400', # Contains sensitive token
    }
}
