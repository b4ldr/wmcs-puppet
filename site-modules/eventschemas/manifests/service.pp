# Class: eventschemas::service
#
# Sets up an nginx site serving a JSON autoindex of files in
# /srv/eventschemas/repositories. This also uses a static dist of
# https://github.com/spring-raining/pretty-autoindex
# to allow for nice browsing of the served schemas.
# In this way, schemas can be explored and requested from the service
# programtically via the JSON autoindex, or alternatively
# browsed in HTML in browser via pretty-autoindex.
#
# E.g:
#
# curl https://schema.wikimedia.org/repositories/primary/jsonschema/mediawiki/
# [
#    { "name":"api", "type":"directory", "mtime":"Mon, 06 Jan 2020 21:49:58 GMT" },
#    { "name":"centralnotice", "type":"directory", "mtime":"Mon, 06 Jan 2020 21:49:58 GMT" },
#    { "name":"cirrussearch", "type":"directory", "mtime":"Mon, 06 Jan 2020 21:49:58 GMT" },
#    { "name":"client", "type":"directory", "mtime":"Thu, 02 Jan 2020 20:37:54 GMT" },
#    { "name":"job", "type":"directory", "mtime":"Thu, 05 Mar 2020 17:55:55 GMT" },
#    { "name":"page", "type":"directory", "mtime":"Fri, 10 Jan 2020 18:50:02 GMT" },
#    { "name":"recentchange", "type":"directory", "mtime":"Fri, 10 Jan 2020 17:49:34 GMT" },
#    { "name":"revision", "type":"directory", "mtime":"Fri, 10 Jan 2020 18:50:02 GMT" },
#    { "name":"user", "type":"directory", "mtime":"Mon, 06 Jan 2020 21:49:58 GMT" },
#    ...
# ]
#
# Or point a browser at http://schema.wikimedia.org to get a pretty-autoindex of repositories/.
#
# == Parameters
#
# [*server_name*]
#   Default: schema.svc.${::site}.wmnet.
#   Will also be used for Access-Control-Allow-Origin if $allow_origin is not set.
#
# [*server_alias*]
#   Default: undef
#
# [*port*]
#   Default: 8190
#
# [*allow_origin*]
#   This will default to server_name.  Set this to something else
#   Default: undef
#
class eventschemas::service(
    String $server_name  = "schema.svc.${::site}.wmnet",
    Optional[Array] $server_alias = undef,
    $port = 8190,
    String $allow_origin = undef,
) {
    require ::eventschemas

    $document_root = "${::eventschemas::base_path}/site"

    # Ensure that all files in files/site are copied to the document root.
    # These include the pretty-autoindex static files.
    file { $document_root:
        ensure  => 'directory',
        source  => 'puppet:///modules/eventschemas/site',
        recurse => 'remote',
    }

    # Use $allow_origin or $server_name for pretty-autoindex client side requests
    file { "${document_root}/config.js":
        content => template('eventschemas/pretty-autoindex-config.js.erb')
    }

    # Symlink the cloned schema repositories_path into the document root.
    file { "${document_root}/repositories":
        ensure => 'link',
        target => $::eventschemas::repositories_path
    }

    nginx::site { $server_name:
        content => template('eventschemas/site.nginx.erb')
    }
}
