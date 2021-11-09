# = Class: role::discovery::bayes
#
# This class sets up R and Python packages for Bayesian inference.
#
class role::product_analytics::bayes {
    # include ::profile::base::production
    # include ::profile::base::firewall
    include ::profile::product_analytics::probabilistic_programming

    system::role { 'role::product_analytics::bayes':
        ensure      => 'present',
        description => 'VM configured for Bayesian inference',
    }

}
