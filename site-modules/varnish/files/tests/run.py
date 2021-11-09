#!/usr/bin/env python3

import os
import re
import sys
import tempfile

import requests

DC = ("eqiad", "codfw", "esams", "ulsfo", "eqsin", "drmrs")
CLUSTERS = ("text", "upload")
PATH_RE = re.compile("^(/etc/varnish/|/usr/share/varnish/)")
COMPILER_RE = re.compile(
    ".*(https://puppet-compiler.wmflabs.org/compiler[0-9]{4}/[0-9]+/)"
)
TIMEOUT = 30

CC_COMMAND = (
    "exec gcc -std=gnu99 -g -O2 -fstack-protector-strong -Wformat "
    "-Werror=format-security -Wall -pthread -fpic -shared -Wl,-x "
    "-o %o %s -lmaxminddb"
)

CWD = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(CWD, os.pardir))


def find_cluster(hostname):
    # eg: cp4021.ulsfo.wmnet -> DC[3] -> 'ulsfo'
    idx = int(hostname[2]) - 1
    dc = DC[idx]

    base = "https://config-master.wikimedia.org"
    for cluster in CLUSTERS:
        url = "{}/pybal/{}/{}".format(base, dc, cluster)
        r = requests.get(url, timeout=TIMEOUT)
        if hostname in r.text:
            return cluster

    raise Exception("Unknown cluster for {}".format(hostname))


def get_pcc_url(hostname, patch_id, pcc):
    cmd = " ".join((pcc, '-N', patch_id, hostname))
    for line in os.popen(cmd).readlines():
        match = COMPILER_RE.match(line)
        if match:
            return match.group(1)

    raise Exception("Issues with get_pcc_url()")


def dump_files(url, hostname):
    catalog_url = "{}/{}/change.{}.pson".format(url, hostname, hostname)
    print("\tCatalog URL: {}".format(catalog_url))

    catalog = requests.get(catalog_url, timeout=TIMEOUT).json()
    for resource in catalog["resources"]:
        if resource["type"] != "File":
            continue
        if PATH_RE.match(resource["title"]) is None:
            continue
        if "content" not in resource["parameters"]:
            continue
        path = os.path.join(PARENT_DIR, resource["title"].lstrip("/"))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            print("\tCreating {}".format(path))
            f.write(resource["parameters"]["content"].encode("utf-8"))


def main(hostname, patch_id, pcc):
    print("[*] running PCC for change {}...".format(patch_id))
    pcc_url = get_pcc_url(hostname, patch_id, pcc)
    print("\tPCC URL: {}\n".format(pcc_url))

    print("[*] Dumping files...")
    dump_files(pcc_url, hostname)
    print()

    print("[*] Finding cluster...")
    cluster = find_cluster(hostname)
    print("\t{} is a cache_{} host\n".format(hostname, cluster))

    print("[*] Running varnishtest (this might take a while)...")
    vcl_path = "{}/usr/share/varnish/tests:{}/etc/varnish".format(PARENT_DIR, PARENT_DIR)
    cluster_vtc_path = os.path.join(CWD, cluster)
    cmd = "{} -Dcc_command='{}' -Dbasepath={} -Dvcl_path={} {}/*.vtc".format(
        "sudo varnishtest -k", CC_COMMAND, PARENT_DIR, vcl_path, cluster_vtc_path
    )
    print("\t{}\n".format(cmd))
    t = tempfile.mkstemp()
    with open(t[1], "w") as f:
        f.write(os.popen(cmd).read())
    print("Test output saved to {}".format(t[1]))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: {} hostname patch_id [pcc_path]".format(sys.argv[0]))
        sys.exit(1)

    if len(sys.argv) == 4:
        pcc = sys.argv[3]
    else:
        pcc = "../../../../utils/pcc"

    main(sys.argv[1], sys.argv[2], pcc)
