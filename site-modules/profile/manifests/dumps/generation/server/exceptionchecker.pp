class profile::dumps::generation::server::exceptionchecker(
    $xmldumpsprivatedir = lookup('profile::dumps::xmldumpsprivatedir'),
) {
    class {'::dumps::generation::server::exceptionchecker':
        dumpsbasedir => $xmldumpsprivatedir,
        user         => 'dumpsgen',
    }
}
