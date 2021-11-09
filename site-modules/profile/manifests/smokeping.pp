# http://oss.oetiker.ch/smokeping/
class profile::smokeping (
    Stdlib::Fqdn $active_server = lookup('netmon_server'),
    Stdlib::Fqdn $passive_server = lookup('netmon_server_failover'),
){

    class{ '::smokeping':
        active_server => $active_server,
    }

    class{ '::smokeping::web': }

    ferm::service { 'smokeping-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'smokeping-https':
        proto => 'tcp',
        port  => '443',
    }

    backup::set { 'smokeping': }
}
