# == Class: profile::opensearch::dashboards
class profile::opensearch::dashboards (
  Enum['1']         $config_version     = lookup('profile::opensearch::dashboards::config_version',     { 'default_value' => '1' }),
  Boolean           $enable_phatality   = lookup('profile::opensearch::dashboards::enable_phatality',   { 'default_value' => true }),
  String            $package_name       = lookup('profile::opensearch::dashboards::package_name',       { 'default_value' => 'opensearch-dashboards' }),
  Optional[Boolean] $tile_map_enabled   = lookup('profile::opensearch::dashboards::tile_map_enabled',   { 'default_value' => undef }),
  Optional[Boolean] $region_map_enabled = lookup('profile::opensearch::dashboards::region_map_enabled', { 'default_value' => undef }),
  Optional[String]  $index              = lookup('profile::opensearch::dashboards::index',              { 'default_value' => undef }),
  Optional[Boolean] $enable_warnings    = lookup('profile::opensearch::dashboards::enable_warnings',    { 'default_value' => undef }),
) {
    class { 'opensearch_dashboards':
      config_version     => $config_version,
      package_name       => $package_name,
      enable_phatality   => $enable_phatality,
      tile_map_enabled   => $tile_map_enabled,
      region_map_enabled => $region_map_enabled,
      index              => $index,
      enable_warnings    => $enable_warnings,
    }
}
