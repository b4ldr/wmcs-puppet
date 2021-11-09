#! /usr/bin/python3
# -*- coding: utf-8 -*-
"""
This script checks whether any dependant library has been refreshed and if
that's the case, a restart is triggered.
"""

import subprocess
import sys
import argparse
import os
import logging
import logging.handlers
import json

if os.geteuid() != 0:
    print("Needs to be run as root")
    sys.exit(1)
CONF_FILE = '/etc/debdeploy-client/config.json'
logger = logging.getLogger('servicerestart')
logger.setLevel(logging.INFO)
handler = logging.handlers.SysLogHandler('/dev/log')
handler.formatter = logging.Formatter('wmf-auto-restart: %(levelname)s: %(asctime)s : %(message)s')
logger.addHandler(handler)


def get_mounts(filesystems):
    '''Return an array of mount points matching file systems'''
    with open('/proc/mounts', 'r') as proc_mounts:
        mounts = [line.split() for line in proc_mounts.readlines()]
        return [mount[1] for mount in mounts if mount[2] in filesystems]


def check_restart(service_name, dry_run, exclude_mounts=None, exclude_filesystems=None):
    """return a list of services that need to be restarted"""
    false_positives = ['/dev/zero']
    command = ["/usr/bin/lsof", "+c", "15", "-nXd", "DEL"]
    if exclude_mounts:
        for exclude_mount in exclude_mounts:
            command += ['-e', exclude_mount]
    if exclude_filesystems:
        for mount in get_mounts(exclude_filesystems):
            command += ['-e', mount]

    try:
        del_files = subprocess.check_output(
            command, universal_newlines=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        logger.info("Could not query the PID(s) of %s: %s", service_name, e.returncode)
        return 1

    logger.debug("All references to deleted files: %s", del_files)

    try:
        rc = subprocess.call(["/bin/systemctl", "is-active", service_name],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        logger.info("Could not query the status of %s: %s", service_name, e.returncode)

    logger.debug("systemctl is-active check returned %s", rc)

    if rc:
        logger.info("Service %s not present or not running", service_name)
        return 1

    # Could switch to systemctl --value at some point
    try:
        pid_query = subprocess.check_output(["/bin/systemctl", "show", "-p", "MainPID",
                                             service_name], universal_newlines=True)
    except subprocess.CalledProcessError as e:
        logger.info("Could not query the PID of %s: %s", service_name, e.returncode)
        return 1

    logger.debug("PID query for MainPID returned %s", pid_query)

    detect_service_pid = str(pid_query.strip()).split("=")[1]

    if detect_service_pid == "0":  # Service using legacy init script and systemd-sysv-generator
        try:
            pid_query = subprocess.check_output(
                ["/bin/pidof", service_name], universal_newlines=True)
        except subprocess.CalledProcessError as error:
            logger.info("Could not query the PID of %s: %s", service_name, error.returncode)
            return 1
        service_pids = pid_query.split()
        native_systemd_unit = False
    else:
        native_systemd_unit = True
        service_pids = [detect_service_pid]

    logger.debug("Service pids: %s", service_pids)

    pids_to_restart = set()
    for line in del_files.splitlines():
        cols = line.split(maxsplit=7)
        try:
            if len(cols) != 8:
                logger.error("Malformed line in lsof output:")
                logger.error(line)
                continue

            command, pid, filename = [cols[x] for x in (0, 1, 7)]
            if filename in false_positives:
                continue

            if pid in service_pids:
                pids_to_restart.add(pid)

        except ValueError:
            logger.error("Malformed line in lsof output:")
            logger.error(line)
            continue

    if pids_to_restart:
        for pid in pids_to_restart:
            logger.info("Detected necessary restart for service %s (%s)", service_name, pid)
            if not native_systemd_unit:
                logger.warning("Service %s uses a legacy sysvinit script", service_name)
                logger.warning("Consider using a systemd unit instead")

            if dry_run:
                logger.info("Skipping restart since --dry-run was specified")
            else:
                cmd = ["/bin/systemctl", "restart", service_name]
                try:
                    restart_output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
                    logger.info("Restarted service %s", service_name)
                    if restart_output:
                        logger.info(restart_output)
                except subprocess.CalledProcessError as e:
                    logger.error("Failed to restart service %s:", service_name)
                    logger.error(e.output)
                    return 1
    else:
        logger.info("No restart necessary for service %s", service_name)

    return 0


def main():
    """Main method"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-s', '--servicename',
                        help='The name of the service for which a restart should be tested',
                        required=True)
    parser.add_argument('--dry-run', action='store_true', dest="dryrun", default=False,
                        help='Do not actually restart, only print a message')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    args = parser.parse_args()

    config = {}
    if os.path.isfile(CONF_FILE):
        with open(CONF_FILE, 'r') as config_file:
            config = json.load(config_file)

    if args.debug:
        logging.getLogger().addHandler(logging.StreamHandler())
        logger.setLevel(logging.DEBUG)

    if args.servicename.lower().endswith('.service'):
        print("You need to provide the base service name, not the name of the systemd unit",
              file=sys.stderr)  # noqa: E999 TODO: remove once tox:pep8 uses python3 T184435
        return 1

    run_time_deps = ('/bin/pidof', '/usr/bin/lsof', '/bin/systemctl')
    missing_run_time_deps = [i for i in run_time_deps if not os.path.isfile(i)]

    if missing_run_time_deps:
        logger.error("Missing run time dependency/dependencies: %s",
                     ' '.join(missing_run_time_deps))
        return 1

    return check_restart(
        args.servicename,
        args.dryrun,
        config.get('exclude_mounts', []),
        config.get('exclude_filesystems', []))


if __name__ == "__main__":
    sys.exit(main())
