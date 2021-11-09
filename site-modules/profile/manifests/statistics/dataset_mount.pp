# == Class profile::statistics::dataset_mount
#
class profile::statistics::dataset_mount (
    $dumps_servers       = lookup('dumps_dist_nfs_servers'),
    $dumps_active_server = lookup('dumps_dist_active_web'),
){
    class { '::statistics::dataset_mount':
        dumps_servers       => $dumps_servers,
        dumps_active_server => $dumps_active_server,
    }
}