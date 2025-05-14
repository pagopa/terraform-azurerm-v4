module "idh_loader" {
  source = "../idh_loader"

  prefix        = var.prefix
  env           = var.env
  idh_resource  = var.idh_resource
  idh_category  = "postgres_flexible_server"
}


module "pgflex" {
  source = "../../postgres_flexible_server"

  administrator_login = var.administrator_login
  administrator_password = var.administrator_password
  db_version = module.idh_loader.idh_config.db_version
  high_availability_enabled = module.idh_loader.idh_config.high_availability_enabled
  standby_availability_zone = module.idh_loader.idh_config.standby_availability_zone
  location = var.location
  name = var.name
  private_endpoint_enabled = module.idh_loader.idh_config.private_endpoint_enabled
  resource_group_name = var.resource_group_name
  sku_name = module.idh_loader.idh_config.sku_name
  storage_mb = module.idh_loader.idh_config.storage_mb

  backup_retention_days        = module.idh_loader.idh_config.backup_retention_days
  geo_redundant_backup_enabled = module.idh_loader.idh_config.geo_redundant_backup_enabled
  create_mode                  = module.idh_loader.idh_config.create_mode
  zone                         = module.idh_loader.idh_config.zone

  delegated_subnet_id = module.idh_loader.idh_config.private_endpoint_enabled ? var.delegated_subnet_id : null
  private_dns_zone_id           = module.idh_loader.idh_config.private_endpoint_enabled ? var.private_dns_zone_id : null
  public_network_access_enabled = module.idh_loader.idh_config.public_network_access_enabled

  customer_managed_key_enabled = var.customer_managed_key_enabled
  customer_managed_key_kv_key_id = var.customer_managed_key_kv_key_id
  primary_user_assigned_identity_id = var.primary_user_assigned_identity_id

  auto_grow_enabled = var.auto_grow_enabled

  maintenance_window_config = module.idh_loader.idh_config.maintenance_window_config

  private_dns_registration = var.private_dns_registration
  private_dns_record_cname = var.private_dns_record_cname
  private_dns_zone_name = var.private_dns_zone_name
  private_dns_zone_rg_name = var.private_dns_zone_rg_name
  private_dns_cname_record_ttl = var.private_dns_cname_record_ttl

  pgbouncer_enabled = module.idh_loader.idh_config.server_parameters.pgbouncer_enabled

  log_analytics_workspace_id = var.log_analytics_workspace_id
  diagnostic_setting_destination_storage_id = var.diagnostic_setting_destination_storage_id
  diagnostic_settings_enabled = var.diagnostic_settings_enabled

  tags = var.tags

}

#
# PG bouncer params
#

# Message    : FATAL: unsupported startup parameter: extra_float_digits
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_ignore_startup_parameters" {
  count     = module.idh_loader.idh_config.server_parameters.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.ignore_startup_parameters"
  server_id = module.pgflex.id
  value     = "extra_float_digits,search_path"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_min_pool_size" {
  count     = module.idh_loader.idh_config.server_parameters.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.min_pool_size"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.pgbouncer_min_pool_size
}
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_default_pool_size" {
  count     = module.idh_loader.idh_config.server_parameters.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.default_pool_size"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.pgbouncer_default_pool_size
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_max_client_conn" {
  count     = module.idh_loader.idh_config.server_parameters.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.max_client_conn"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.pgbouncer_max_client_conn
}



resource "azurerm_postgresql_flexible_server_configuration" "max_worker_process" {
  name      = "max_worker_processes"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.max_worker_processes
}

resource "azurerm_postgresql_flexible_server_configuration" "wal_level" {
  name      = "wal_level"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.wal_level
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_preoload_libraries" {
  name      = "shared_preload_libraries"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.shared_preload_libraries
}

resource "azurerm_postgresql_flexible_server_configuration" "azure_extensions" {
  name      = "azure.extensions"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_config.server_parameters.azure_extensions
}


#
# Databases
#
resource "azurerm_postgresql_flexible_server_database" "database" {
  for_each  = toset(var.databases)
  name      = each.value
  server_id = module.pgflex.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}


