# Class: profile::toolforge::genpp::python_exec_stretch
#
# This file was auto-generated by genpp.py using the following command:
# modules/profile/manifests/toolforge/genpp/python.py
#
# Please do not edit manually!

class profile::toolforge::genpp::python_exec_stretch {
    ensure_packages([
        'python-babel',         # 2.3.4
        'python3-babel',        # 2.3.4
        'python-beautifulsoup', # 3.2.1
        # python3-beautifulsoup is not available
        'python-bottle',        # 0.12.13
        'python3-bottle',       # 0.12.13
        'python-bs4',           # 4.5.3
        'python3-bs4',          # 4.5.3
        'python-celery',        # 3.1.23
        'python3-celery',       # 3.1.23
        'python-cffi',          # 1.9.1
        'python3-cffi',         # 1.9.1
        'python-dev',           # 2.7.13
        'python3-dev',          # 3.5.3
        'python-egenix-mxdatetime', # 3.2.9
        # python3-egenix-mxdatetime is not available
        'python-egenix-mxtools', # 3.2.9
        # python3-egenix-mxtools is not available
        'python-enum34',        # 1.1.6
        # python3-enum34 is not available
        'python-flake8',        # 3.2.1
        'python3-flake8',       # 3.2.1
        'python-flask',         # 0.12.1
        'python3-flask',        # 0.12.1
        # python-flask-login is not available
        'python3-flask-login',  # 0.4.0
        'python-flickrapi',     # 2.1.2
        'python3-flickrapi',    # 2.1.2
        'python-flup',          # 1.0.2
        # python3-flup is not available
        'python-gdal',          # 2.1.2
        'python3-gdal',         # 2.1.2
        'python-gdbm',          # 2.7.13
        'python3-gdbm',         # 3.5.3
        'python-genshi',        # 0.7
        'python3-genshi',       # 0.7
        'python-genshi-doc',    # 0.7
        # python3-genshi-doc is not available
        'python-geoip',         # 1.3.2
        'python3-geoip',        # 1.3.2
        'python-gevent',        # 1.1.2
        'python3-gevent',       # 1.1.2
        'python-gi',            # 3.22.0
        'python3-gi',           # 3.22.0
        'python-greenlet',      # 0.4.11
        'python3-greenlet',     # 0.4.11
        'python-httplib2',      # 0.9.2
        'python3-httplib2',     # 0.9.2
        'python-imaging',       # 4.0.0
        # python3-imaging is not available
        'python-ipaddr',        # 2.1.11
        # python3-ipaddr is not available
        # python-irclib is not available
        # python3-irclib is not available
        'python-keyring',       # 10.1
        'python3-keyring',      # 10.1
        'python-launchpadlib',  # 1.10.4
        'python3-launchpadlib', # 1.10.4
        'python-lxml',          # 3.7.1
        'python3-lxml',         # 3.7.1
        'python-magic',         # 1:5.30
        'python3-magic',        # 1:5.30
        'python-matplotlib',    # 2.0.0
        'python3-matplotlib',   # 2.0.0
        'python-mysql.connector', # 2.1.6
        'python3-mysql.connector', # 2.1.6
        'python-mysqldb',       # 1.3.7
        'python3-mysqldb',      # 1.3.7
        'python-newt',          # 0.52.19
        'python3-newt',         # 0.52.19
        'python-nose',          # 1.3.7
        'python3-nose',         # 1.3.7
        'python-numpy',         # 1:1.12.1
        'python3-numpy',        # 1:1.12.1
        'python-opencv',        # 2.4.9.1
        # python3-opencv is not available
        'python-pandas',        # 0.19.2
        'python3-pandas',       # 0.19.2
        'python-pathlib2',      # 2.2.0
        # python3-pathlib2 is not available
        'python-pil',           # 4.0.0
        'python3-pil',          # 4.0.0
        # python-problem-report is not available
        # python3-problem-report is not available
        'python-psycopg2',      # 2.6.2
        'python3-psycopg2',     # 2.6.2
        'python-pycountry',     # 1.8
        'python3-pycountry',    # 1.8
        'python-pydot',         # 1.0.28
        'python3-pydot',        # 1.0.28
        'python-pyexiv2',       # 0.3.2
        # python3-pyexiv2 is not available
        'python-pygments',      # 2.2.0
        'python3-pygments',     # 2.2.0
        'python-pyicu',         # 1.9.5
        # python3-pyicu is not available
        'python-pyinotify',     # 0.9.6
        'python3-pyinotify',    # 0.9.6
        'python-requests-oauthlib', # 0.7.0
        'python3-requests-oauthlib', # 0.7.0
        'python-rsvg',          # 2.32.0
        # python3-rsvg is not available
        'python-scipy',         # 0.18.1
        'python3-scipy',        # 0.18.1
        'python-sqlalchemy',    # 1.0.15
        'python3-sqlalchemy',   # 1.0.15
        'python-svn',           # 1.9.4
        'python3-svn',          # 1.9.4
        'python-tk',            # 2.7.13
        'python3-tk',           # 3.5.3
        'python-twisted',       # 16.6.0
        'python3-twisted',      # 16.6.0
        'python-twitter',       # 1.1
        # python3-twitter is not available
        'python-unicodecsv',    # 0.14.1
        'python3-unicodecsv',   # 0.14.1
        'python-unittest2',     # 1.1.0
        'python3-unittest2',    # 1.1.0
        # python-venv is not available
        'python3-venv',         # 3.5.3
        'python-virtualenv',    # 15.1.0
        'python3-virtualenv',   # 15.1.0
        'python-wadllib',       # 1.3.2
        'python3-wadllib',      # 1.3.2
        'python-webpy',         # 1:0.38
        # python3-webpy is not available
        'python-werkzeug',      # 0.11.15
        'python3-werkzeug',     # 0.11.15
        'python-zbar',          # 0.10
        # python3-zbar is not available
        'python-zmq',           # 16.0.2
        'python3-zmq',          # 16.0.2
    ])
}
