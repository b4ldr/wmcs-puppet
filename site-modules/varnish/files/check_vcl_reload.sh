#!/bin/sh

. /usr/lib/nagios/plugins/utils.sh

STATE_FILE="/var/run/reload-vcl-state"

# No reload-vcl has happened, apparently.
# No reason to raise an alarm then
if [ ! -f $STATE_FILE ]; then
    echo "reload-vcl has not been executed yet."
    exit $STATE_OK
fi

HOUR=3600 #seconds
MIN=60
NOW=$(date +%s) # Unix time
STATEAGE=$(( $NOW - $(stat -c %Y ${STATE_FILE}) ))
STATEHOURS=$(( $STATEAGE / $HOUR ))
REMNANT=$(( $STATEAGE - $STATEHOURS * $HOUR ))
STATEMINS=$(( $REMNANT / $MIN ))

STATE=$(cat ${STATE_FILE})
if [ "x${STATE}" = "xOK" ]; then
    echo "reload-vcl successfully ran ${STATEHOURS}h, ${STATEMINS} minutes ago."
    exit $STATE_OK
else
    echo "reload-vcl failed to run since ${STATEHOURS}h, ${STATEMINS} minutes."
    exit $STATE_CRITICAL
fi
