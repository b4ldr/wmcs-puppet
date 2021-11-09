#!/bin/bash
# Copyright © 2020 Chris Danis, the Wikimedia Foundation, & contributors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Usage: prometheus-phpfpm-statustext [systemd unit name] [output path]
# Parses the StatusText from php-fpm's systemd integration, preserving stats
# that would be otherwise lost when all php-fpm workers are busy.
# https://phabricator.wikimedia.org/T252605

set -eu
set -o pipefail

UNIT="${1:-php7.2-fpm.service}"
OUTFILE="${2:-/var/lib/prometheus/node.d/phpfpm-statustext.prom}"

# If our service isn't running, nothing to do.
/bin/systemctl is-active --quiet "$UNIT" || exit 0

# Scrape available metrics from the status text, exiting on failure.
SEDSCRIPT='s!^StatusText=Processes active: ([0-9]+), idle: ([0-9]+),'
SEDSCRIPT+=' Requests: ([0-9]+), slow: ([0-9]+), Traffic: ([0-9.]+)req/sec$'
SEDSCRIPT+='!\1 \2 \3 \4 \5!; t; Q99'  # if no match, exit 99 without printing

PARSED="$(systemctl show -p StatusText php7.2-fpm.service \
          | sed -E "$SEDSCRIPT")"

TMPOUTFILE="${OUTFILE}.$$"
function cleanup {
    rm -f "$TMPOUTFILE"
}
trap cleanup EXIT

# Now write output.
echo "$PARSED" | (read procs_act procs_idle req_total req_slow_total rps
cat <<EOF >"$TMPOUTFILE"
# HELP phpfpm_statustext_processes Number of php-fpm worker processes in each state
# TYPE phpfpm_statustext_processes gauge
phpfpm_statustext_processes{service="${UNIT}",state="active"} ${procs_act}
phpfpm_statustext_processes{service="${UNIT}",state="idle"} ${procs_idle}

# HELP phpfpm_statustext_requests_total Number of requests served by this worker pool
# TYPE phpfpm_statustext_requests_total counter
phpfpm_statustext_requests_total{service="${UNIT}"} ${req_total}

# HELP phpfpm_statustext_slow_requests_total Number of slow requests served by this worker pool
# TYPE phpfpm_statustext_slow_requests_total counter
phpfpm_statustext_slow_requests_total{service="${UNIT}"} ${req_slow_total}
EOF
)

mv "$TMPOUTFILE" "$OUTFILE"
