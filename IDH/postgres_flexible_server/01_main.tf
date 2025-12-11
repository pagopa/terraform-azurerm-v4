module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "postgres_flexible_server"
}

locals {
  pgbouncer_enabled = var.pg_bouncer_enabled != null ? var.pg_bouncer_enabled : module.idh_loader.idh_resource_configuration.server_parameters.pgbouncer_enabled
  zone              = var.zone != null ? var.zone : module.idh_loader.idh_resource_configuration.zone
}

# IDH/subnet
module "pgflex_snet" {
  count                = var.embedded_subnet.enabled ? 1 : 0
  source               = "../subnet"
  name                 = "${var.name}-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name
  service_endpoints    = ["Microsoft.Storage"]

  env               = var.env
  idh_resource_tier = "postgres_flexible"
  product_name      = var.product_name
}

# IDH/subnet
module "pgflex_replica_snet" {
  count                = var.embedded_subnet.enabled && var.geo_replication.enabled ? 1 : 0
  source               = "../subnet"
  name                 = "${var.name}-snet"
  resource_group_name  = var.embedded_subnet.replica_vnet_rg_name
  virtual_network_name = var.embedded_subnet.replica_vnet_name
  service_endpoints    = ["Microsoft.Storage"]

  env               = var.env
  idh_resource_tier = "postgres_flexible"
  product_name      = var.product_name
}


# -------------------------------------------------------------------
# Postgres Flexible Server
# -------------------------------------------------------------------
module "pgflex" {
  source = "../../postgres_flexible_server"

  administrator_login       = var.administrator_login
  administrator_password    = var.administrator_password
  db_version                = var.db_version != null ? var.db_version : module.idh_loader.idh_resource_configuration.db_version
  high_availability_enabled = module.idh_loader.idh_resource_configuration.high_availability_enabled
  standby_availability_zone = module.idh_loader.idh_resource_configuration.standby_availability_zone
  location                  = var.location
  name                      = var.name
  private_endpoint_enabled  = module.idh_loader.idh_resource_configuration.private_endpoint_enabled
  resource_group_name       = var.resource_group_name
  sku_name                  = module.idh_loader.idh_resource_configuration.sku_name
  storage_mb                = var.storage_mb != null ? var.storage_mb : module.idh_loader.idh_resource_configuration.storage_mb
  storage_tier              = var.storage_tier != null ? var.storage_tier : null

  backup_retention_days        = module.idh_loader.idh_resource_configuration.backup_retention_days
  geo_redundant_backup_enabled = contains(module.idh_loader.non_paired_locations, var.location) ? false : module.idh_loader.idh_resource_configuration.geo_redundant_backup_enabled
  create_mode                  = module.idh_loader.idh_resource_configuration.create_mode
  zone                         = local.zone

  delegated_subnet_id           = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? module.pgflex_snet[0].subnet_id : var.delegated_subnet_id) : null
  private_dns_zone_id           = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? var.private_dns_zone_id : null
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled

  customer_managed_key_enabled      = var.customer_managed_key_enabled
  customer_managed_key_kv_key_id    = var.customer_managed_key_kv_key_id
  primary_user_assigned_identity_id = var.primary_user_assigned_identity_id

  auto_grow_enabled = var.auto_grow_enabled

  maintenance_window_config = module.idh_loader.idh_resource_configuration.maintenance_window_config

  private_dns_registration     = var.private_dns_registration
  private_dns_record_cname     = var.private_dns_record_cname
  private_dns_zone_name        = var.private_dns_zone_name
  private_dns_zone_rg_name     = var.private_dns_zone_rg_name
  private_dns_cname_record_ttl = var.private_dns_cname_record_ttl

  pgbouncer_enabled = local.pgbouncer_enabled

  log_analytics_workspace_id                = var.log_analytics_workspace_id
  diagnostic_setting_destination_storage_id = var.diagnostic_setting_destination_storage_id
  diagnostic_settings_enabled               = var.diagnostic_settings_enabled

  custom_metric_alerts = var.custom_metric_alerts
  alerts_enabled       = module.idh_loader.idh_resource_configuration.alerts_enabled
  alert_action         = module.idh_loader.idh_resource_configuration.alerts_enabled ? var.alert_action : []

  tags = var.tags

}

#
# PG bouncer params
#

# Message    : FATAL: unsupported startup parameter: extra_float_digits
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_ignore_startup_parameters" {
  count     = local.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.ignore_startup_parameters"
  server_id = module.pgflex.id
  value     = "extra_float_digits,search_path"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_min_pool_size" {
  count     = local.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.min_pool_size"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.server_parameters.pgbouncer_min_pool_size
}
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_default_pool_size" {
  count     = local.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.default_pool_size"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.server_parameters.pgbouncer_default_pool_size
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_max_client_conn" {
  count     = local.pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.max_client_conn"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.server_parameters.pgbouncer_max_client_conn
}



resource "azurerm_postgresql_flexible_server_configuration" "max_worker_process" {
  name      = "max_worker_processes"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.server_parameters.max_worker_processes
}

resource "azurerm_postgresql_flexible_server_configuration" "wal_level" {
  name      = "wal_level"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.server_parameters.wal_level
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_preoload_libraries" {
  name      = "shared_preload_libraries"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.server_parameters.shared_preload_libraries
}

resource "azurerm_postgresql_flexible_server_configuration" "azure_extensions" {
  name      = "azure.extensions"
  server_id = module.pgflex.id
  value     = length(var.additional_azure_extensions) > 0 ? join(",", [module.idh_loader.idh_resource_configuration.server_parameters.azure_extensions, join(",", var.additional_azure_extensions)]) : module.idh_loader.idh_resource_configuration.server_parameters.azure_extensions
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = module.pgflex.id
  value     = module.idh_loader.idh_resource_configuration.max_connections
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

#
# Replica
#

module "replica" {
  source = "../../postgres_flexible_server_replica"
  count  = var.geo_replication.enabled && module.idh_loader.idh_resource_configuration.geo_replication_allowed ? 1 : 0

  name                = var.geo_replication.name
  resource_group_name = var.resource_group_name
  location            = var.geo_replication.location

  private_dns_zone_id      = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? var.private_dns_zone_id : null
  delegated_subnet_id      = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? module.pgflex_replica_snet[0].subnet_id : var.geo_replication.subnet_id) : null
  private_endpoint_enabled = module.idh_loader.idh_resource_configuration.private_endpoint_enabled

  sku_name = module.idh_loader.idh_resource_configuration.sku_name

  high_availability_enabled = false
  pgbouncer_enabled         = local.pgbouncer_enabled

  storage_mb = module.idh_loader.idh_resource_configuration.storage_mb

  source_server_id = module.pgflex.id #NEWGPD-DB : DEPRECATED switch to new istance postgres_flexible_server_private_db

  diagnostic_settings_enabled = false

  log_analytics_workspace_id = var.log_analytics_workspace_id
  zone                       = local.zone
  tags                       = var.tags

}


resource "azurerm_postgresql_flexible_server_virtual_endpoint" "virtual_endpoint" {
  count             = var.geo_replication.enabled && module.idh_loader.idh_resource_configuration.geo_replication_allowed ? 1 : 0
  name              = "${var.name}-ve"
  source_server_id  = module.pgflex.id
  replica_server_id = module.replica[0].id
  type              = "ReadWrite"
}

resource "azurerm_private_dns_cname_record" "cname_record" {
  count               = var.geo_replication.enabled && var.geo_replication.private_dns_registration_ve && module.idh_loader.idh_resource_configuration.geo_replication_allowed ? 1 : 0
  name                = var.private_dns_record_cname
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg_name
  ttl                 = var.private_dns_cname_record_ttl
  record              = "${azurerm_postgresql_flexible_server_virtual_endpoint.virtual_endpoint[0].name}.writer.postgres.database.azure.com"
}


