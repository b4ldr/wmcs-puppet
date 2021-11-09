#!/usr/bin/python3
#
# Copyright 2019 Wikimedia Foundation and contributors
#
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
import argparse
import collections
import logging
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

from prometheus_client import (
    CollectorRegistry,
    Counter,
    Gauge,
    write_to_textfile,
)
from prometheus_client.exposition import generate_latest

logger = logging.getLogger(__name__)
SGE_ROOT = "/data/project/.system_sge/gridengine"
RE_JOBLINE = re.compile(r"\s+\d")


def get_job_count():
    """
    Get sequential all time job count. This might be empty temporarily as
    there's a race condition on write/read from it, so we retry a couple times.
    """
    retries = 3
    jobseqnum_path = SGE_ROOT + "/spool/qmaster/jobseqnum"
    while retries:
        with open(jobseqnum_path, "r") as f:
            try:
                return int(f.read().strip())
            except ValueError as err:
                retries -= 1
                if retries:
                    logger.error(
                        (
                            "Error while trying to read jobseqnum from "
                            "{}, {} retries remaining"
                        ).format(jobseqnum_path, retries)
                    )
                    time.sleep(0.1)

                else:
                    # raising here to retain the previous exception context
                    raise Exception(
                        "Failed all tries to get jobseqnum from "
                        + jobseqnum_path
                    ) from err

    # Should never get here
    raise Exception("Failed all tries to get jobseqnum from " + jobseqnum_path)


def grid_cmd(cmd):
    logger.debug("Running %s", cmd)
    try:
        return subprocess.check_output(
            cmd, env={"SGE_ROOT": SGE_ROOT}, universal_newlines=True
        )
    except subprocess.CalledProcessError as e:
        logger.warning(
            "Output from failed shell command %s: %s", cmd, e.output
        )
        raise e


def get_jobs(queue):
    """Retrieve all users job output for a queue."""
    return grid_cmd(["/usr/bin/qstat", "-q", queue, "-u", "*"]).splitlines()[
        1:
    ]


def get_queues():
    queues = grid_cmd(["/usr/bin/qconf", "-sql"])
    return [q for q in queues.splitlines()]


def job_state_stats(jobs):
    """Count jobs per state."""
    stats = collections.defaultdict(int)
    for j in jobs:
        fields = j.split()
        if len(fields) >= 4:
            stats[fields[4]] += 1
    return stats


def get_exec_hosts():
    return grid_cmd(["/usr/bin/qconf", "-sel"]).splitlines()


def get_jobs_by_host(host):
    output = grid_cmd(["/usr/bin/qhost", "-j", "-h", host])
    return [line for line in output.splitlines() if RE_JOBLINE.match(line)]


def get_queue_problems():
    output = grid_cmd(["/usr/bin/qstat", "-f", "-xml", "-explain", "aAcE"])
    queue_problems = []
    xml_root = ET.fromstring(output)
    for queue in xml_root[0]:
        if queue.find("state") is not None:
            if queue.find("state").text == "d":
                continue

            queue_name_fields = queue.find("name").text.split("@")
            queue_problems.append(
                [
                    queue_name_fields[1],
                    queue_name_fields[0],
                    queue.find("state").text,
                ]
            )
    return queue_problems


def get_disabled_queues():
    output = grid_cmd(["/usr/bin/qstat", "-f", "-xml"])
    d_queues = []
    xml_root = ET.fromstring(output)
    for queue in xml_root[0]:
        if queue.find("state") is not None:
            if queue.find("state").text == "d":
                queue_name_fields = queue.find("name").text.split("@")
                d_queues.append([queue_name_fields[1], queue_name_fields[0]])
    return d_queues


def collect_sge_stats(registry):
    # This rolls over at 10million
    jobseqnum = Counter(
        "jobseqnum", "Job sequence number", namespace="sge", registry=registry
    )
    jobseqnum.inc(get_job_count())

    # Active jobs per (queue, state)
    queuejobs = Gauge(
        "queuejobs",
        "Concurrent jobs per queue",
        ("queue", "state"),
        namespace="sge",
        registry=registry,
    )
    for q in get_queues():
        logger.debug("Examining queue %s", q)
        jobs = get_jobs(q)
        states = job_state_stats(jobs)
        for state, scount in states.items():
            queuejobs.labels(queue=q, state=state).inc(scount)

    # Active jobs per host
    hostjobs = Gauge(
        "hostjobs",
        "Concurrent jobs per host",
        ("host",),
        namespace="sge",
        registry=registry,
    )
    for line in get_exec_hosts():
        host = line.strip()
        jcount = len(get_jobs_by_host(host))
        hostjobs.labels(host=host).inc(jcount)

    queueproblems = Gauge(
        "queueproblems",
        "Queues or hosts that aren't healthy",
        ("host", "queue", "state"),
        namespace="sge",
        registry=registry,
    )
    for prob in get_queue_problems():
        host, queue, state = prob
        queueproblems.labels(host=host, state=state, queue=queue).inc()

    disabledqueues = Gauge(
        "disabledqueues",
        "Hosts/queues that are depooled",
        ("host", "queue"),
        namespace="sge",
        registry=registry,
    )
    for dqueue in get_disabled_queues():
        disabledqueues.labels(host=dqueue[0], queue=dqueue[1]).inc()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--outfile", metavar="FILE.prom", help="Output file (stdout)"
    )
    parser.add_argument(
        "-d",
        "--debug",
        dest="log_level",
        action="store_const",
        const=logging.DEBUG,
        default=logging.WARNING,
        help="Enable debug logging (false)",
    )
    args = parser.parse_args()

    logging.basicConfig(level=args.log_level)

    if args.outfile and not args.outfile.endswith(".prom"):
        parser.error("Output file does not end with .prom")

    registry = CollectorRegistry()
    collect_sge_stats(registry)

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode("utf-8"))


if __name__ == "__main__":
    sys.exit(main())
