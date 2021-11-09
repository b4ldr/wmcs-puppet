# realm.pp
# Collection of global definitions used across sites, within one realm.
#

# Determine the site the server is in

$site = $facts['ipaddress'] ? {
    /^208\.80\.15[23]\./                                      => 'codfw',
    /^208\.80\.15[45]\./                                      => 'eqiad',
    /^10\.6[48]\./                                            => 'eqiad',
    /^10\.19[26]\./                                           => 'codfw',
    /^91\.198\.174\./                                         => 'esams',
    /^198\.35\.26\./                                          => 'ulsfo',
    /^10\.128\./                                              => 'ulsfo',
    /^10\.20\.0\./                                            => 'esams',
    /^103\.102\.166\./                                        => 'eqsin',
    /^10\.132\./                                              => 'eqsin',
    /^185\.15\.58\./                                          => 'drmrs',
    /^10\.136\./                                              => 'drmrs',
    /^172\.16\.([0-9]|[1-9][0-9]|1([0-1][0-9]|2[0-7]))\./     => 'eqiad',
    /^172\.16\.(1(2[8-9]|[3-9][0-9])|2([0-4][0-9]|5[0-5]))\./ => 'codfw',
    default                                                   => '(undefined)'
}
$realm = 'labs'
# Pull the project name from the certname. CloudVPS VM certs can be:
#  * <hostname>.<projname>.<site>.wmflabs
#  * <hostname>.<projname>.<deployment>.wikimedia.cloud
#
# See following page for additional context:
# https://wikitech.wikimedia.org/wiki/Wikimedia_Cloud_Services_team/EnhancementProposals/DNS_domain_usage#Resolution
$pieces = $trusted['certname'].split('[.]')

# current / legacy FQDN.
# This whole branch will go away eventually
if $pieces[-1] == 'wmflabs' {
    if $pieces[2] != $site {
        fail("Incorrect site in certname. Should be ${site} but is ${pieces[2]}")
    }
    $labsproject = $pieces[1]
    $wmcs_deployment = $pieces[2] ? {
        'eqiad' => 'eqiad1',
        'codfw' => 'codfw1dev',
        default => fail("site (${pieces[2]}) is not supported")
    }
} else {
    # new FQDN wikimedia.cloud
    $labsproject = $pieces[1] # $wmcs_project may make more sense
    $wmcs_deployment = $pieces[2]
}

# some final checks before we move on
if $pieces[0] != $::hostname {
    fail("Cert hostname ${pieces[0]} does not match reported hostname ${::hostname}")
}
if $::labsproject == undef {
    fail('Failed to determine $::labsproject')
}
if $::wmcs_deployment == undef {
    fail('Failed to determine $::wmcs_deployment')
}
$projectgroup = "project-${labsproject}"
$dnsconfig = lookup('labsdnsconfig',Hash, 'hash', {})
$nameservers = [
    ipresolve($dnsconfig['recursor'], 4),
    ipresolve($dnsconfig['recursor_secondary'], 4)
]

# This is used to define the fallback site and is to be used by applications that
# are capable of automatically detecting a failed service and falling back to
# another one. Only the 2 sites that make sense to really be here are added for
# now
$other_site = $site ? {
    'codfw' => 'eqiad',
    'eqiad' => 'codfw',
    default => '(undefined)'
}

$network_zone = $facts['ipaddress'] ? {
    /^10./  => 'internal',
    default => 'public'
}

$numa_networking = 'off'
