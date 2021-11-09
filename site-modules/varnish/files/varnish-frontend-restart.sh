#!/bin/bash

set -e

# Depool ats-tls
confctl --quiet select name=`hostname -f`,service='ats-tls' set/pooled=no

# Depool varnish-fe
confctl --quiet select name=`hostname -f`,service='varnish-fe' set/pooled=no

# Wait a bit for the service to be drained
sleep 20

# Restart varnish-frontend
/usr/sbin/service varnish-frontend restart

sleep 15

# Repool varnish-fe
confctl --quiet select name=`hostname -f`,service='varnish-fe' set/pooled=yes

# Repool ats-tls
confctl --quiet select name=`hostname -f`,service='ats-tls' set/pooled=yes
