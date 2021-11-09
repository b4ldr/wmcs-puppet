#!/usr/bin/python3

import logging
import re
import socket

import mwopenstackclients
import rbd2backy2
import yaml


def exclude_server(config, project, servername):
    if project in config["exclude_servers"].keys():
        for exp in config["exclude_servers"][project]:
            if re.fullmatch(exp, servername):
                return True
    return False


def backup_this_project_on_this_host(config, project):
    # This should return the short hostname, e.g. 'cloudvirt1024'
    hostname = socket.gethostname()

    if config["project_assignments"].get(project, "").lower() == "ignore":
        return False

    if project in config["project_assignments"]:
        return config["project_assignments"][project] == hostname

    return config["project_assignments"].get("ALLOTHERS", "") == hostname


with open("/etc/wmcs_backup_instances.yaml") as f:
    config = yaml.safe_load(f)

openstackclients = mwopenstackclients.Clients(envfile="/etc/novaobserver.yaml")
ceph_servers = rbd2backy2.ceph_vms(config["ceph_pool"])

for project in openstackclients.allprojects():
    if not backup_this_project_on_this_host(config, project.id):
        continue

    servers = openstackclients.allinstances(projectid=project.id)

    not_in_ceph = []
    for server in servers:
        if exclude_server(config, project.id, server.name):
            continue

        if server.id in ceph_servers:
            logging.info("Backing up %s:%s" % (project, server.name))
            rbd2backy2.backup_vm(
                config["ceph_pool"], server.id, config["live_for_days"]
            )
        else:
            not_in_ceph.append(server)

    if not_in_ceph:
        logging.warning(
            "In project %s the following servers are not in ceph:" % project.id
        )
        for server in not_in_ceph:
            logging.warning(" - %s (%s)" % (server.name, server.id))
