#!/usr/bin/env bash

[[ $HOSTNAME =~ wdqs2.* ]] && sleep $[ ( $RANDOM % 600 )  + 1 ] && sudo systemctl restart wdqs-blazegraph || echo "Not a codfw wdqs host, skipping"
