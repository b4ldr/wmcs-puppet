#!/usr/bin/python3

import sys

import mwopenstackclients


certname = sys.argv[1]
clients = mwopenstackclients.clients(envfile="/etc/novaobserver.yaml")
region_recs = clients.keystoneclient().regions.list()
regions = [region.id for region in region_recs]

pieces = certname.split(".")

if len(pieces) == 4:
    if pieces[3] != "wmflabs":
        sys.exit("certname %s does not end with wmflabs" % certname)
    if pieces[2] != "eqiad" and pieces[2] != "codfw":
        sys.exit("certname %s is for an invalid site" % certname)
elif len(pieces) == 5:
    if pieces[4] != "cloud":
        sys.exit("certname %s does not end with cloud" % certname)
    if pieces[3] != "wikimedia":
        sys.exit(
            "certname %s ends with cloud but does not include wikimedia" % certname
        )
    if pieces[2] != "eqiad1" and pieces[2] != "codfw1dev":
        sys.exit("certname %s is for an invalid deployment" % certname)
else:
    sys.exit("certname %s is formatted incorrectly" % certname)

certhostname = pieces[0]
certproject = pieces[1]

projects = [project.id for project in clients.allprojects()]
if certproject not in projects:
    sys.exit("certname %s is not for a real project" % certname)

# the cert name will always be lowercase.  So we need to lower()
#  the instance name for proper comparison
for region in regions:
    instances = [
        instance.name.lower()
        for instance in clients.novaclient(certproject, region=region).servers.list()
    ]
    if certhostname in instances:
        exit(0)

sys.exit("certname %s is not for a real instance" % certname)
