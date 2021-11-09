#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  usage: mwgrep [-h] [--max-results N] [--timeout N] [--user | --module]
                [--title TITLE | --etitle REGEX] [--no-private] regex

  Grep for Lua, CSS, JS and JSON code fragments on (per default) MediaWiki wiki pages

  positional arguments:
    regex            regex to search for

  optional arguments:
    -h, --help       show this help message and exit
    --max-results N  show at most this many results (default: 100)
    --timeout N      abort search after this many seconds (default: 30)
    --user           search NS_USER rather than NS_MEDIAWIKI
    --module         search NS_MODULE rather than NS_MEDIAWIKI
    --title TITLE    restrict search to pages with this exact title
    --etitle REGEX   restrict search to pages with this title pattern
    --no-private     show only results from public wikis (may result in less than max-results results)

  mwgrep will grep the MediaWiki namespace across Wikimedia wikis. specify
  --user to search the user namespace instead. See the lucene documentation
  for org.apache.lucene.util.automaton.RegExp for supported syntax. The current
  lucene version is available from `curl search.svc.eqiad.wmnet:9200`.

"""  # noqa: E501
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import argparse
import bisect
from itertools import chain
import json
import requests


TIMEOUT = 30

# These are the search "index types" cirrus uses for storing wikipages (file is only for commons)
TYPES = ["content", "file", "general"]
# Port 9243 queries the chi cluster. Access the omega and psi clusters through chi
# by using elasticsearch cross-cluster-search uri syntax.
REMOTE_CLUSTERS = ["psi", "omega"]
SEARCH_ENDPOINT = 'https://search.svc.eqiad.wmnet:9243/'

NS_MEDIAWIKI = 8
NS_USER = 2
NS_MODULE = 828
PREFIX_NS = {
    NS_MEDIAWIKI: 'MediaWiki:',
    NS_USER: 'User:',
    NS_MODULE: 'Module:'
}

ap = argparse.ArgumentParser(
    prog='mwgrep',
    description='Grep for CSS, JS and JSON code fragments in MediaWiki wiki pages',
    epilog='mwgrep will grep the MediaWiki namespace across Wikimedia wikis. '
           'specify --user to search the user namespace instead.'
)
ap.add_argument('term', help='text to search for')

ap.add_argument(
    '--max-results',
    metavar='N',
    type=int, default=100,
    help='show at most this many results (default: 100)'
)

ap.add_argument(
    '--timeout',
    metavar='N',
    type='{0}s'.format,
    default='30',
    help='abort search after this many seconds (default: 30)'
)

ap.add_argument(
    '--no-private',
    action='store_true',
    help='Restricts search to public wikis'
)

ns_group = ap.add_mutually_exclusive_group()
ns_group.add_argument(
    '--user',
    action='store_const',
    const=NS_USER,
    default=NS_MEDIAWIKI,
    dest='ns',
    help='search NS_USER rather than NS_MEDIAWIKI'
)

ns_group.add_argument(
    '--module',
    action='store_const',
    const=NS_MODULE,
    default=NS_MEDIAWIKI,
    dest='ns',
    help='search NS_MODULE rather than NS_MEDIAWIKI'
)

title_group = ap.add_mutually_exclusive_group()
title_group.add_argument(
    '--title',
    help='restrict search to pages with this exact title (sans namespace)'
)
title_group.add_argument(
    '--etitle',
    help='restrict search to pages with this title pattern (sans namespace)'
)

args = ap.parse_args()

filters = [
    {'term': {'namespace': str(args.ns)}},
    {'source_regex': {
        'regex': args.term,
        'field': 'source_text',
        'ngram_field': 'source_text.trigram',
        'max_determinized_states': 20000,
        'max_expand': 10,
        'case_sensitive': True,
        'locale': 'en',
    }},
]


if args.title is not None:
    filters.append({'term': {'title.keyword': args.title}})
elif args.etitle is not None:
    filters.append({'regexp': {'title.keyword': args.etitle}})
elif args.ns == NS_USER or args.ns == NS_MEDIAWIKI:
    filters.append({'regexp': {'title.keyword': '(Gadgets-definition|.*\\.(js|css|json))'}})

search = {
    'size': args.max_results,
    '_source': ['namespace', 'title'],
    'sort': ['_doc'],
    'query': {'bool': {'filter':  filters}},
    'stats': ['mwgrep'],
}

query = {
    'timeout': args.timeout,
}

matches = {'public': [], 'private': []}
try:
    # cirrus uses multiple indices per wiki, in general 2: wiki_content and
    # wiki_general, commons has an extra one for files. Here we rely on this
    # naming convention: *_content will match all wikis content indices.
    # Overall we want to search for *_content,*_general,*_file as it should
    # cover all the live indices used by cirrus.
    # TODO: Using the CirrusSearch metastore might be a good improvement as
    # this technique only relies on a naming convention.
    local_indices = map(lambda t: "*_" + t, TYPES)

    # We need to build this same list for all remote clusters:
    # cluster_name:*_content,cluster_name:*_general,cluster_name:*_file
    def prefix_local_indices_with_cluster_name(cluster_name):
        return map(lambda local_index: cluster_name + ":" + local_index, local_indices)

    remote_indices = list(chain(*map(prefix_local_indices_with_cluster_name, REMOTE_CLUSTERS)))

    # we should have a flat list with all local and remote indices:
    # e.g.:
    # ['*_content', '*_file', '*_general',
    #  'psi:*_content', 'psi:*_file', 'psi:*_general',
    #  'omega:*_content', 'omega:*_file', 'omega:*_general']
    all_indices = local_indices + remote_indices

    endpoint = SEARCH_ENDPOINT + ','.join(all_indices) + '/_search'
    resp = requests.post(endpoint, params=query, json=search)
    try:
        full_result = resp.json()
        if resp.status_code >= 400:
            error_body = resp.json()
            if 'error' in error_body and 'root_cause' in error_body['error']:
                for root_cause in error_body['error']['root_cause']:
                    if root_cause['type'] == 'invalid_regex_exception':
                        sys.stderr.write(
                            'Error while parsing regular expression: {0}\n{1}\n'.format(
                                args.term, root_cause['reason']))
                        exit(1)
                sys.stderr.write('Unknown error: {0}\n'.format(json.dumps(error_body, indent=4)))
                exit(1)
            else:
                sys.stderr.write(
                    'Received unexpected json body from elasticsearch:\n{0}\n'.format(
                        json.dumps(error_body, indent=4, separators=(',', ': '))))
            exit(1)
    except ValueError as e:
        sys.stderr.write(
            "Error '{0}' while parsing elasticsearch response '{1}'.\n".format(
                e.message, json.dumps(full_result, indent=4, separators=(',', ': '))))
        exit(1)

    result = full_result['hits']

    private_wikis = open('/srv/mediawiki/dblists/private.dblist').read().splitlines()

    for hit in result['hits']:
        index_name = hit['_index']
        if ':' in index_name:
            # strip cross-cluster identifier
            _, index_name = index_name.split(':', 1)
        db_name = index_name.rsplit('_', 2)[0]
        title = hit['_source']['title']
        page_name = '%s%s' % (PREFIX_NS[args.ns], title)
        if db_name in private_wikis:
            bisect.insort(matches['private'], (db_name, page_name))
        else:
            bisect.insort(matches['public'], (db_name, page_name))

    if matches['public']:
        if matches['private'] and args.no_private is False:
            print('## Public wiki results')
        for db_name, page_name in matches['public']:
            print('{:<20}{}'.format(db_name, page_name))

    total = result['total']
    hits = len(result['hits'])

    if args.no_private:
        private_len = len(matches['private'])
        total -= private_len
        hits -= private_len
    elif matches['private']:
        if matches['public']:
            print('')
        print('## Private wiki results')
        for db_name, page_name in matches['private']:
            print('{:<20}{}'.format(db_name, page_name))

    print('')
    print('(total: %s, shown: %s)' % (total, hits))
    if full_result['timed_out']:
        print("""
The query was unable to complete within the alloted time. Only partial results
are shown here, and the reported total hits is <= the true value. To speed up
the query:

* Ensure the regular expression contains one or more sets of 3 contiguous
  characters. A character range ([a-z]) won't be expanded to count as
  contiguous if it matches more than 10 characters.
* Use a simpler regular expression. Consider breaking the query up into
  multiple queries where possible.
""")

except requests.exceptions.RequestException as error:
    sys.stderr.write("Failed to connect to elastic {0}.\n".format(error))
    exit(1)
