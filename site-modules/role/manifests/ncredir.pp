class role::ncredir {
    system::role { 'ncredir': description => 'Non canonical domains redirection service' }
    include profile::base::production
    include profile::base::firewall
    # TODO: use ::profile::lvs::realserver instead
    include lvs::realserver  # lint:ignore:wmf_styleguide
    include profile::nginx
    include profile::ncredir
}
