# == Class: base::remote_syslog
#
# Configure rsyslog to forward log events to a central server
#
# === Parameters
#
# [*enable*]
#   Enable log forwarding. Should be set to false on the central server.
#
# [*central_hosts*]
#   A list of host (and optional port) to forward syslog events to.
#   (e.g. ["centrallog1001.eqiad.wmnet"] or ["deployment-logstash03.deployment-prep.eqiad1.wikimedia.cloud:10514"])
#
# [*central_hosts_tls*]
#   A list of host:port (port is *required*) to forward syslog using TLS.
#   (e.g. ["centrallog1001.eqiad.wmnet:6514"])
#
# [*queue_size*]
#   Local queue size, unit is messages. Setting to 0 disables the local queue.
#

class base::remote_syslog (
    Boolean $enable,
    Array[String] $central_hosts = [],
    Array[String] $central_hosts_tls = [],
    Integer $queue_size = 10000,
) {
    $owner = 'root'
    $group = 'root'

    if $enable {
        ensure_packages('rsyslog-gnutls')

        if empty($central_hosts) and empty($central_hosts_tls) {
            fail('::base::remote_syslog::central_hosts or central_hosts_tls required')
        }

        if ! empty($central_hosts_tls) {
            file { '/etc/rsyslog':
                ensure => 'directory',
                owner  => $owner,
                group  => $group,
                mode   => '0400',
                before => Base::Expose_puppet_certs['/etc/rsyslog'],
            }

            ::base::expose_puppet_certs { '/etc/rsyslog':
                provide_private => true,
                user            => $owner,
                group           => $group,
            }
        }

        rsyslog::conf { 'remote_syslog':
            content  => template('base/remote_syslog.conf.erb'),
            priority => 30,
        }
    }
    # No ensure=>absent handling is needed for the $enable == false case
    # because ::rsyslog uses recursive purge to manage the files in its config
    # directory. Simply not adding the file will cause Puppet to remove it if
    # present.
}
