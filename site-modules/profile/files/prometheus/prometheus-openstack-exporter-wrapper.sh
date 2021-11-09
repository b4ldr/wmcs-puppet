#!/bin/bash

# this is a simple thin wrapper to load env variables required by the Openstack
# API before running the prometheus exporter as non-root user.
# I'm open to suggestions if this can be replaced by something more elegant.

if [ "$(id -u)" != "0" ] ; then
	echo "ERROR: ${0}: root required" >&2
	exit 1
fi

set -e
source /root/novaenv.sh
sudo -E -u prometheus /usr/bin/prometheus-openstack-exporter /etc/prometheus-openstack-exporter.yaml
