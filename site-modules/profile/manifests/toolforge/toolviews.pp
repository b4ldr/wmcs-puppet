# == Class: profile::toolforge::toolviews
#
class profile::toolforge::toolviews (
    $mysql_host     = lookup('profile::toolforge::toolviews::mysql_host',     {default_value => 'localhost'}),
    $mysql_db       = lookup('profile::toolforge::toolviews::mysql_db',       {default_value => 'example_db'}),
    $mysql_user     = lookup('profile::toolforge::toolviews::mysql_user',     {default_value => 'example_user'}),
    $mysql_password = lookup('profile::toolforge::toolviews::mysql_password', {default_value => 'example_passwd'}),
){
    # due to wrong or missing DB credentials, toolviews will produce cronspam
    # if not running in the tools project. If you want to run this in toolsbeta
    # make sure you provide relevant hiera keys and update the following if:
    if $::labsproject == 'tools' {
        class { '::toolforge::toolviews':
            mysql_host     => $mysql_host,
            mysql_db       => $mysql_db,
            mysql_user     => $mysql_user,
            mysql_password => $mysql_password,
        }
    }
}
