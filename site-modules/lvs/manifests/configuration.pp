# lvs/configuration.pp

class lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1013', 'lvs1016' ],
                'codfw' => [ 'lvs2007', 'lvs2010' ],
                'esams' => [ 'lvs3005', 'lvs3007' ],
                'ulsfo' => [ 'lvs4005', 'lvs4007' ],
                'eqsin' => [ 'lvs5001', 'lvs5003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1014', 'lvs1016' ],
                'codfw' => [ 'lvs2008', 'lvs2010' ],
                'esams' => [ 'lvs3006', 'lvs3007' ],
                'ulsfo' => [ 'lvs4006', 'lvs4007' ],
                'eqsin' => [ 'lvs5002', 'lvs5003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1015', 'lvs1016' ],
                'codfw' => [ 'lvs2009', 'lvs2010' ],
                'esams' => [ ],
                'ulsfo' => [ ],
                'eqsin' => [ ],
                default => undef,
            },
            'labs' => $::labsproject ? {
                'deployment-prep' => [ ],
                default => undef,
            },
            default => undef,
        },
    }

    # This is technically redundant information from $lvs_class_hosts, but
    # transforming one into the other in puppet is a huge PITA.
    $lvs_class = $::hostname ? {
        'lvs1013'      => 'high-traffic1',
        'lvs1014'      => 'high-traffic2',
        'lvs1015'      => 'low-traffic',
        'lvs1016'      => 'secondary',
        'lvs2007'      => 'high-traffic1',
        'lvs2008'      => 'high-traffic2',
        'lvs2009'      => 'low-traffic',
        'lvs2010'      => 'secondary',
        'lvs3005'      => 'high-traffic1',
        'lvs3006'      => 'high-traffic2',
        'lvs3007'      => 'secondary',
        'lvs4005'      => 'high-traffic1',
        'lvs4006'      => 'high-traffic2',
        'lvs4007'      => 'secondary',
        'lvs5001'      => 'high-traffic1',
        'lvs5002'      => 'high-traffic2',
        'lvs5003'      => 'secondary',
        default        => 'unknown',
    }
}
