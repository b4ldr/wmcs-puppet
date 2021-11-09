# @summary a define to add a certificate to the system java truststore
# or to a custom one.
# @param path the location of the CA pem file to add to the truststore
# @param storepass the keystore password
# @param keystore_path optional, the keystore to create (instead of using
# the system one).
define java::cacert (
    Stdlib::Unixpath           $path,
    Wmflib::Ensure             $ensure        = 'present',
    String                     $storepass     = 'changeit',
    Optional[Stdlib::Unixpath] $keystore_path = undef,
) {
    include java

    if $keystore_path != undef {
        $keystore = "-keystore ${keystore_path}"
        $trust_cacert = ''
    } else {
        $keystore = $java::default_java_package['version'] ? {
            '7'     => '-keystore /etc/ssl/certs/java/cacerts',
            '8'     => '-keystore /etc/ssl/certs/java/cacerts',
            default => '-cacerts',
        }
        $trust_cacert = '-trustcacerts'
    }
    $import_cmd = @("IMPORT"/L)
        /usr/bin/keytool -import ${trust_cacert} -noprompt ${keystore} \
            -file ${path} -storepass ${storepass} -alias ${title}
        | IMPORT
    $delete_cmd = "/usr/bin/keytool -delete ${keystore} -noprompt -storepass ${storepass} -alias ${title}"
    $validate_cmd = "/usr/bin/keytool -list ${keystore} -noprompt -storepass ${storepass} -alias ${title}"
    if $ensure == 'present' {
        exec {"java__cacert_${title}":
            command => $import_cmd,
            unless  => $validate_cmd,
        }
    } else {
        exec {"java__cacert_${title}":
            command => $delete_cmd,
            onlyif  => $validate_cmd,
        }
    }
}
