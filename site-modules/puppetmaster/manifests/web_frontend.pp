# == Define puppetmaster::web_frontend
#
# Allows to define a virtual host (and the corresponding ssl needs)
# for a puppetmaster frontend.
#
# === Parameters
#
# [*workers*]
#   Array of hashes in the form. If 'loadfactor' is omitted, it is assumed to
#   be equal to 1.
#   An 'offline' parameter is supported to allow fully depooling a host
#   without removing it from the stanza.
#   A 'canary' parameter configures a backend to only receive canary hosts
#    [{ 'worker' => 'worker1.example.com', loadfactor => '1' }]
#
# [*master*]
#   The fqdn of the master frontend (e.g. puppetmaster1001.eqiad.wmnet)
#
# [*bind_address*]
#   IP address to bind to.
#
# [*priority*]
#   The priority of the apache vhost. Defaults to 90
#
# [*alt_names*]
#   Alternative names, if any, which should be accepted.
#
# [*cert_secret_path*]
#   Path to puppet keys/certs in secrets repository.
#
# [*ssl_ca_revocation_check*]
#   CRL-based revocation checking setting in apache. See apache
#   SSLCARevocationCheck documentation for full details.
#   Valid settings: chain|leaf|none
# [*canary_hosts*]
#  An array of hosts which should be directed to use canary servers
# [*locale_server*]
#  Puppet 5.10 now supports providing localised strings.  Once a server
#  has had a catalogue compiled by a puppet 5.10 master it will expect
#  to receive better data for any localised files.  this parameter ensures
#  requests are sent to a puppet master with locals support
define puppetmaster::web_frontend(
    Puppetmaster::Backends                  $workers,
    Stdlib::Host                            $master,
    String[1]                               $bind_address            = '*',
    Integer[1,100]                          $priority                = 90,
    String[1]                               $cert_secret_path        = 'puppetmaster',
    Integer[1,2]                            $ssl_verify_depth        = 1,
    Optional[Array[String]]                 $alt_names               = undef,
    Optional[Enum['chain', 'leaf', 'none']] $ssl_ca_revocation_check = undef,
    Optional[Array[Stdlib::Host]]           $canary_hosts            = [],
    Optional[Stdlib::Host]                  $locale_server           = undef,
){
    $server_name = $title
    $ssl_settings = ssl_ciphersuite('apache', 'strong')

    if $server_name != $::fqdn {
        # The files called with secret() should be generated on the current
        # puppetmaster::ca_server with "puppet cert generate" and committed to
        # the private repository.
        # We use the private repo for the public key as well as it gets
        # generated on the puppet ca server.
        file { "${facts['puppet_config']['ssldir']}/certs/${server_name}.pem":
            content   => secret("${cert_secret_path}/${server_name}_pubkey.pem"),
            owner     => 'puppet',
            group     => 'puppet',
            mode      => '0640',
            before    => Httpd::Site[$server_name],
            show_diff => false,
        }

        file { "${facts['puppet_config']['ssldir']}/private_keys/${server_name}.pem":
            content   => secret("${cert_secret_path}/${server_name}_privkey.pem"),
            owner     => 'puppet',
            group     => 'puppet',
            mode      => '0640',
            before    => Httpd::Site[$server_name],
            show_diff => false,
        }
    }
    httpd::site { $server_name:
        ensure   => present,
        content  => template('puppetmaster/web-frontend.conf.erb'),
        priority => $priority,
    }

}
