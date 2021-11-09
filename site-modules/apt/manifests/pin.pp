define apt::pin (
    String         $pin,
    Integer        $priority,
    String         $package       = $name,
    Wmflib::Ensure $ensure        = present,
) {
    include apt
    # Braces required on puppet < 5.4 PUP-8067
    $filename = ($name =~ /\.pref$/) ? {
        true    => $name.regsubst('[^\w\.]', '_', 'G'),
        default => "${name.regsubst('\W', '_', 'G')}.pref",
    }

    $_notify = defined('$notify') ? {
        true => $notify,
        default => Exec['apt-get update'],
    }

    file { "/etc/apt/preferences.d/${filename}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "Package: ${package}\nPin: ${pin}\nPin-Priority: ${priority}\n",
        notify  => $_notify,
    }
}
