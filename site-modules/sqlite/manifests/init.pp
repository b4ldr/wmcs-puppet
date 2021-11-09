# @summary install sqlite
class sqlite (
    Wmflib::Ensure            $ensure          = 'present',
    Stdlib::Unixpath          $default_db_path = '/var/lib/sqlite',
    Enum['sqlite', 'sqlite3'] $sqlite_cmd      = 'sqlite3'
){
    ensure_packages(['sqlite'], {'ensure' => $ensure })
    ensure_resource('file', $default_db_path, {'ensure' => stdlib::ensure($ensure, 'directory')})
}
