class profile::mediawiki::maintenance::update_special_pages {
    profile::mediawiki::periodic_job { 'update_special_pages':
        # TODO: Instead of flock, make this unit run every N time units after it's finished.
        command  => 'flock -n /var/lock/update-special-pages /usr/local/bin/foreachwiki updateSpecialPages.php',
        interval => '*-1/3 05:00'
    }
}
