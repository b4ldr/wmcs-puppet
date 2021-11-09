# = Class: role::product_analytics::deep_learner
#
# This class sets up R and Python packages for machine learning with deep
# neural networks.
#
class role::product_analytics::deep_learner {
    # include ::profile::base::production
    # include ::profile::base::firewall
    include ::profile::product_analytics::deep_learning

    system::role { 'role::product_analytics::deep_learner':
        ensure      => 'present',
        description => 'VM configured for deep learning',
    }

}
