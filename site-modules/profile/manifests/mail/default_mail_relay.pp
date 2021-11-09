class profile::mail::default_mail_relay (
    Boolean $enabled  = lookup('profile::mail::default_mail_relay::enabled'),
    String  $template = lookup('profile::mail::default_mail_relay::template'),
    Array[String] $mail_smarthost = lookup('mail_smarthost')
) {
    if $enabled {
        class { 'exim4':
            queuerunner => 'combined',
            config      => template($template),
        }

        profile::auto_restarts::service { 'exim4': }
    }
}
