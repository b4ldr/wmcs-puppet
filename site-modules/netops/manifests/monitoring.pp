# == Class: netops::monitoring
#
# Sets up monitoring checks for networking equipment.
#
# === Parameters
#
# [*atlas_measurements*]
# a hash of datacenter => ipv4 and ipv6 measurement IDs
#
# === Examples
#
#  include netops::monitoring

class netops::monitoring(
    Hash[String, Hash] $atlas_measurements,
) {
    include passwords::network

    # core routers
    $routers_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        critical       => true,
        interfaces     => true,
        bfd            => true,
        bgp            => true,
        os             => 'Junos',
        ospf           => true,
    }
    #############################################################################################################
    ###### WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ######
    ######                                                                                                 ######
    ###### profile::druid::turnilo makes use of the information populated in $routers via query_resources. ######
    ###### One needs to ensure any changes made here are compatible with the use case in that profile      ######
    ###### specifically we use the following so the bgp and bfd attributes are significant:                ######
    ######      query_resources(false, 'Netops::Check[~".*"]{bgp=true and bfd=true}'                       ######
    ######                                                                                                 ######
    ###### WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ######
    #############################################################################################################
    $routers = {
        # eqiad
        'cr1-eqiad'  => { ipv4 => '208.80.154.196',  ipv6 => '2620:0:861:ffff::1',  vrrp_peer => 'cr2-eqiad.wikimedia.org'},
        'cr2-eqiad'  => { ipv4 => '208.80.154.197',  ipv6 => '2620:0:861:ffff::2' },
        'pfw3-eqiad'  => { ipv4 => '208.80.154.219', parents => ['cr1-eqiad', 'cr2-eqiad'], bfd => false, alarms => false, },
        # eqord
        'cr2-eqord'  => { ipv4 => '208.80.154.198',  ipv6 => '2620:0:861:ffff::5', alarms => false,},
        # codfw
        'cr1-codfw'  => { ipv4 => '208.80.153.192',  ipv6 => '2620:0:860:ffff::1', vrrp_peer => 'cr2-codfw.wikimedia.org'},
        'cr2-codfw'  => { ipv4 => '208.80.153.193',  ipv6 => '2620:0:860:ffff::2', },
        'pfw3-codfw' => { ipv4 => '208.80.153.197',  parents => ['cr1-codfw', 'cr2-codfw'], bfd => false, alarms => false, },
        # eqdfw
        'cr2-eqdfw'  => { ipv4 => '208.80.153.198',  ipv6 => '2620:0:860:ffff::5', alarms => false, },
        # esams
        'cr3-esams'  => { ipv4 => '91.198.174.245',  ipv6 => '2620:0:862:ffff::5', vrrp_peer => 'cr2-esams.wikimedia.org'},
        'cr2-esams'  => { ipv4 => '91.198.174.244',  ipv6 => '2620:0:862:ffff::3' },
        'cr3-knams'  => { ipv4 => '91.198.174.246',  ipv6 => '2620:0:862:ffff::4', alarms => false, },
        # ulsfo
        'cr3-ulsfo'  => { ipv4 => '198.35.26.192',   ipv6 => '2620:0:863:ffff::1', alarms => false, vrrp_peer => 'cr4-ulsfo.wikimedia.org'},
        'cr4-ulsfo'  => { ipv4 => '198.35.26.193',   ipv6 => '2620:0:863:ffff::2', alarms => false, },
        # eqsin
        'cr2-eqsin'  => { ipv4 => '103.102.166.130', ipv6 => '2001:df2:e500:ffff::3', alarms => false, },
        'cr3-eqsin'  => { ipv4 => '103.102.166.131', ipv6 => '2001:df2:e500:ffff::4', alarms => false, vrrp_peer => 'cr2-eqsin.wikimedia.org'},
    }
    create_resources(netops::check, $routers, $routers_defaults)

    # mgmt routers
    $mgmt_routers_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        interfaces     => true,
        os             => 'Junos',
        ospf           => true,
    }
    $mgmt_routers = {
        'mr1-eqiad'  => { ipv4 => '208.80.154.199',  ipv6 => '2620:0:861:ffff::6', parents => ['asw2-a-eqiad'] },
        'mr1-codfw'  => { ipv4 => '208.80.153.196',  ipv6 => '2620:0:860:ffff::6', parents => ['asw-a-codfw'] },
        'mr1-esams'  => { ipv4 => '91.198.174.247',  ipv6 => '2620:0:862:ffff::1', parents => ['asw2-esams.mgmt.esams.wmnet'] },
        'mr1-ulsfo'  => { ipv4 => '198.35.26.194',   ipv6 => '2620:0:863:ffff::6', parents => ['asw2-ulsfo'] },
        'mr1-eqsin'  => { ipv4 => '103.102.166.128', ipv6 => '2001:df2:e500:ffff::1', parents => ['asw1-eqsin'] },
        'mr1-drmrs'  => { ipv4 => '185.15.58.130', ipv6 => '2a02:ec80:600:ffff::3', parents => ['asw1-b12-drmrs.wikimedia.org',
                                                                                                'asw1-b13-drmrs.wikimedia.org'] },

    }
    create_resources(netops::check, $mgmt_routers, $mgmt_routers_defaults)

    # OOB interfaces -- no SNMP for these
    $oob = {
        'mr1-eqiad.oob' => { ipv4 => '149.97.228.94',  ipv6 => '2607:f6f0:1000:1194::2', parents => ['mr1-eqiad'] },
        'mr1-codfw.oob' => { ipv4 => '216.117.46.36', parents => ['mr1-codfw'] },
        'mr1-esams.oob' => { ipv4 => '164.138.24.90', parents => ['mr1-esams'] },
        'mr1-ulsfo.oob' => { ipv4 => '198.24.47.102',   ipv6 => '2607:fb58:9000:7::2',  parents => ['mr1-ulsfo'] },
        'mr1-eqsin.oob' => { ipv4 => '27.111.227.106',  ipv6 => '2403:b100:3001:9::2',  parents => ['mr1-eqsin'] },
        'mr1-drmrs.oob' => { ipv4 => '193.251.154.146',  ipv6 => '2001:688:0:4::2d4',  parents => ['mr1-drmrs'] },
        're0.cr1-eqiad' => { ipv4 => '10.65.0.12',      parents => ['msw1-eqiad'] },
        're0.cr2-eqiad' => { ipv4 => '10.65.0.14',      parents => ['msw1-eqiad'] },
        're0.cr1-codfw' => { ipv4 => '10.193.0.10',     parents => ['msw1-codfw'] },
        're0.cr2-codfw' => { ipv4 => '10.193.0.12',     parents => ['msw1-codfw'] },
        're0.cr3-esams' => { ipv4 => '10.21.0.119',     parents => ['mr1-esams'] },
        're0.cr2-esams' => { ipv4 => '10.21.0.117',     parents => ['mr1-esams'] },
        're0.cr3-ulsfo' => { ipv4 => '10.128.128.4',    parents => ['mr1-ulsfo'] },
        're0.cr4-ulsfo' => { ipv4 => '10.128.128.5',    parents => ['mr1-ulsfo'] },
        're0.cr3-eqsin' => { ipv4 => '10.132.128.7',    parents => ['mr1-eqsin'] },
        're0.cr2-eqsin' => { ipv4 => '10.132.128.6',    parents => ['mr1-eqsin'] },
        'asw1-b12-drmrs' => { ipv4 => '10.136.128.3',   parents => ['mr1-drmrs'] },
        'asw1-b13-drmrs' => { ipv4 => '10.136.128.4',   parents => ['mr1-drmrs'] },
    }
    create_resources(netops::check, $oob)

    # access/management/peering switches
    $switches_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        os             => 'Junos',
        vcp            => true,
    }
    # Note: The parents attribute is used to capture a view of the network
    # topology. It is not complete on purpose as icinga is not able to
    # work well with loops
    $switches = {
        # eqiad
        'asw2-a-eqiad'  => { ipv4 => '10.65.0.21',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw2-b-eqiad'  => { ipv4 => '10.65.0.25',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw2-c-eqiad'  => { ipv4 => '10.65.0.26',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw2-d-eqiad'  => { ipv4 => '10.65.0.27',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'msw1-eqiad'    => { ipv4 => '10.65.0.10',   parents => ['mr1-eqiad'], vcp => false },
        'fasw-c-eqiad'  => { ipv4 => '10.65.0.30',   parents => ['pfw3-eqiad'] },
        'cloudsw1-c8-eqiad.mgmt.eqiad.wmnet' => { ipv4    => '10.65.0.7',
                                                  parents => ['cr1-eqiad', 'cr2-eqiad'],
                                                  vcp => false },
        'cloudsw2-c8-eqiad.mgmt.eqiad.wmnet' => { ipv4    => '10.65.1.197',
                                                  parents => ['cloudsw1-c8-eqiad.mgmt.eqiad.wmnet'],
                                                  vcp => false },
        'cloudsw1-d5-eqiad.mgmt.eqiad.wmnet' => { ipv4    => '10.65.0.6',
                                                  parents => ['cr1-eqiad', 'cr2-eqiad'],
                                                  vcp => false },
        'cloudsw2-d5-eqiad.mgmt.eqiad.wmnet' => { ipv4    => '10.65.1.198',
                                                  parents => ['cloudsw1-d5-eqiad.mgmt.eqiad.wmnet'],
                                                  vcp => false },
        # codfw
        'asw-a-codfw'   => { ipv4 => '10.193.0.16',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'asw-b-codfw'   => { ipv4 => '10.193.0.17',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'asw-c-codfw'   => { ipv4 => '10.193.0.18',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'asw-d-codfw'   => { ipv4 => '10.193.0.19',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'msw1-codfw'    => { ipv4 => '10.193.0.3',   parents => ['mr1-codfw'], vcp => false },
        'fasw-c-codfw'  => { ipv4 => '10.193.0.57',  parents => ['pfw3-codfw'] },
        # esams
        # fully qualified due to a more recent JunOS; see PR1383295
        'asw2-esams.mgmt.esams.wmnet' => { ipv4 => '10.21.0.8',  parents => ['cr3-esams', 'cr2-esams'] },
        # ulsfo
        'asw2-ulsfo'    => { ipv4 => '10.128.128.7', parents => ['cr3-ulsfo', 'cr4-ulsfo'] },
        # eqsin
        'asw1-eqsin'    => { ipv4 => '10.132.128.4', parents => ['cr2-eqsin', 'cr3-eqsin'] },
        # drmrs
        'asw1-b12-drmrs.wikimedia.org' => { ipv4 => '185.15.58.131',
                                            ipv6 => '2a02:ec80:600:ffff::4',
                                            # parents => ['cr1-drmrs', 'cr2-drmrs'],
                                            vcp => false },
        'asw1-b13-drmrs.wikimedia.org' => { ipv4 => '185.15.58.132',
                                            ipv6 => '2a02:ec80:600:ffff::5',
                                            # parents => ['cr1-drmrs', 'cr2-drmrs'],
                                            vcp => false },
    }
    create_resources(netops::check, $switches, $switches_defaults)

    # RIPE Atlases -- no SNMP for these
    $atlas = {
        'ripe-atlas-eqiad' => { ipv4 => '208.80.155.69',  ipv6 => '2620:0:861:202:208:80:155:69', parents => ['asw2-b-eqiad'] },
        'ripe-atlas-codfw' => { ipv4 => '208.80.152.244', ipv6 => '2620:0:860:201:208:80:152:244', parents => ['asw-a-codfw'] },
        'ripe-atlas-esams' => { ipv4 => '91.198.174.132', ipv6 => '2620:0:862:201:91:198:174:132', parents => ['asw2-esams.mgmt.esams.wmnet'] },
        'ripe-atlas-ulsfo' => { ipv4 => '198.35.26.244',  ipv6 => '2620:0:863:201:198:35:26:244', parents => ['asw2-ulsfo'] },
        'ripe-atlas-eqsin' => { ipv4 => '103.102.166.20', ipv6 => '2001:df2:e500:201:103:102:166:20', parents => ['asw1-eqsin'] },
    }
    create_resources(netops::check, $atlas)

    # RIPE Atlas Anchor measurements -- implicit dependency on the above host checks
    create_resources(netops::ripeatlas, $atlas_measurements)

    # SCS -- Serial Console Servers
    $scs = {
        'scs-a8-eqiad'   => { ipv4 => '10.65.0.11',    parents => ['msw1-eqiad'] },
        'scs-c1-eqiad'   => { ipv4 => '10.65.0.22',    parents => ['msw1-eqiad'] },
        'scs-a1-codfw'   => { ipv4 => '10.193.0.14',   parents => ['msw1-codfw'] },
        'scs-c1-codfw'   => { ipv4 => '10.193.0.15',   parents => ['msw1-codfw'] },
        'scs-oe16-esams' => { ipv4 => '10.21.0.9',     parents => ['mr1-esams'] },
        'scs-ulsfo'      => { ipv4 => '10.128.128.11', parents => ['mr1-ulsfo'] },
        'scs-eqsin'      => { ipv4 => '10.132.128.5',  parents => ['mr1-eqsin'] },
        'scs-drmrs'      => { ipv4 => '10.136.128.5',  parents => ['mr1-drmrs'] },
    }
    create_resources(netops::check, $scs)
}
