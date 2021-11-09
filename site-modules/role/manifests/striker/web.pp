# == Class: role::striker::web
#
# Striker is a Django application for managing data related to Toolforge
# tools.
#
class role::striker::web {

    ensure_packages('libapache2-mod-wsgi-py3')
    class { 'httpd':
        modules => ['alias', 'ssl', 'rewrite', 'headers', 'wsgi',
                    'proxy', 'expires', 'proxy_http', 'proxy_balancer',
                    'lbmethod_byrequests'],
    }

    include profile::base::production
    include memcached
    include striker::apache
    include striker::uwsgi
    require passwords::striker
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
