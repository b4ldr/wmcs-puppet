# like role::mediawiki::jobrunner but without LVS and envoy
class role::beta::mediawiki::jobrunner {
    system::role { 'beta::mediawiki::jobrunner': }

    include ::profile::base::firewall

    # Parent role (we don't use inheritance by choice)
    include ::role::mediawiki::common

    include ::profile::prometheus::apache_exporter
    include ::profile::mediawiki::jobrunner
    include ::profile::mediawiki::videoscaler
    include ::profile::mediawiki::php::monitoring
    include ::profile::prometheus::php_fpm_exporter

    # restart php-fpm if the opcache available is too low
    include ::profile::mediawiki::php::restarts
}
