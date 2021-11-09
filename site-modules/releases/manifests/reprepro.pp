# == Class: releases::reprepro
#
#   Configures reprepro for releases.wikimedia.org
#
#   This configuration will keep everything reprepro-related under $basedir,
#   save for the exported files which are published under $outdir and thus
#   under the releases document root.
#
#   Packages can be uploaded into $incomingdir in the form of .changes files,
#   currently any valid gpg signature will be allowed (i.e. any key that's in
#   the public keyring).
#
#   The result will be signed by the default key present in the secret
#   keyring.
#
#   This is a reprepro setup specific to releases* servers.
#   If you are looking for reprepo as installed on APT servers such
#   as apt1001.wikimedia.org, see role::apt_repo instead.
#
class releases::reprepro (
    Stdlib::Unixpath $basedir = '/srv/org/wikimedia/reprepro',
    Stdlib::Unixpath $outdir = '/srv/org/wikimedia/releases/debian',
    Stdlib::Unixpath $homedir = '/var/lib/reprepro',
    Stdlib::Unixpath $incomingdir = "${basedir}/incoming",
) {

    class { '::aptrepo':
        basedir         => $basedir,
        homedir         => $homedir,
        options         => ["outdir ${outdir}"],
        gpg_pubring     => 'releases/pubring.gpg',
        gpg_secring     => 'releases/secring.gpg',
        incomingdir     => $incomingdir,
        authorized_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIRN3017QJUoewK7PIKwMo2ojSl4Mu/YxDZC4NsryXmi4kKlCTN0DTeyVSlnDei56EngwYP1crshCCDZAzFECRMV5Hr3NmS/J+ICR0z6GQztd7bQEORot38wxOkOCXBtmqMgztAqyYv6SH3Qfn9qmjrw6/yW0lLqg6cejmYXF61YEYrXyZJm+hjOD1oaYsCdjkuE+3Ob+8t6KvTcvjxarr99RRcuKp67j+7g/HRzxDKGi8/Z8/wFIBu50W/6idhjyPzYIunU5ThFmcpHUdry4jTB1/whuec70wsgcdC6EKPVVp00BfSwBaRJKlVCMWvI1VilLpMC2WtLZXpSQ5iTJ1'],
    }

    file { $outdir:
        ensure  => directory,
        owner   => 'reprepro',
        group   => 'reprepro',
        mode    => '0755',
        require => Class['::aptrepo'],
    }
}

