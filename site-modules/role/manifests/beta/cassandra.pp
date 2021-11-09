# == Class role::beta::cassandra
#
# Ad-hoc Cassandra clusters for deployment-prep.
class role::beta::cassandra {
    system::role { 'Basic Cassandra cluster': }
    include profile::base::production
    include profile::cassandra
}
