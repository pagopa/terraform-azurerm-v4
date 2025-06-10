module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "cosmosdb_account"
}

# -------------------------------------------------------------------
# CosmosDB Account
# -------------------------------------------------------------------
module "cosmosdb_account" {
  source = "../../cosmosdb_account"

  # 1. Basic Identification
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  domain              = var.domain

  # 2. Core Settings from Loader
  kind                 = module.idh_loader.idh_resource_configuration.kind
  offer_type           = module.idh_loader.idh_resource_configuration.offer_type
  mongo_server_version = module.idh_loader.idh_resource_configuration.server_version

  # 3. Geo-location and Zone Settings
  main_geo_location_location       = var.main_geo_location_location
  main_geo_location_zone_redundant = module.idh_loader.idh_resource_configuration.main_geo_location_zone_redundant
  additional_geo_locations         = module.idh_loader.idh_resource_configuration.additional_geo_replication_allowed ? var.additional_geo_locations : []

  # 4. Security and Networking
  is_virtual_network_filter_enabled  = module.idh_loader.idh_resource_configuration.is_virtual_network_filter_enabled
  public_network_access_enabled      = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  allowed_virtual_network_subnet_ids = var.allowed_virtual_network_subnet_ids
  minimal_tls_version                = module.idh_loader.idh_resource_configuration.minimal_tls_version
  key_vault_key_id                   = var.key_vault_key_id

  # 5. Consistency and Capabilities
  consistency_policy = {
    consistency_level       = module.idh_loader.idh_resource_configuration.consistency_policy.consistency_level
    max_interval_in_seconds = module.idh_loader.idh_resource_configuration.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = module.idh_loader.idh_resource_configuration.consistency_policy.max_staleness_prefix
  }
  capabilities = module.idh_loader.idh_resource_configuration.capabilities

  # 6. Backup and Failover
  backup_continuous_enabled = module.idh_loader.idh_resource_configuration.backup_continuous_enabled
  backup_periodic_enabled = length(keys(module.idh_loader.idh_resource_configuration.backup_periodic_enabled)) > 0 && !module.idh_loader.idh_resource_configuration.backup_continuous_enabled ? {
    interval_in_minutes = try(module.idh_loader.idh_resource_configuration.backup_periodic_enabled.interval_in_minutes, null)
    retention_in_hours  = try(module.idh_loader.idh_resource_configuration.backup_periodic_enabled.retention_in_hours, null)
    storage_redundancy  = try(module.idh_loader.idh_resource_configuration.backup_periodic_enabled.storage_redundancy, null)
  } : null
  enable_automatic_failover = module.idh_loader.idh_resource_configuration.enable_automatic_failover

  # 7. Advanced Options

  ## Throughput and scalability
  burst_capacity_enabled                       = module.idh_loader.idh_resource_configuration.burst_capacity_enabled
  enable_free_tier                             = module.idh_loader.idh_resource_configuration.enable_free_tier
  enable_provisioned_throughput_exceeded_alert = module.idh_loader.idh_resource_configuration.enable_provisioned_throughput_exceeded_alert
  provisioned_throughput_exceeded_threshold    = module.idh_loader.idh_resource_configuration.provisioned_throughput_exceeded_threshold

  ## IP and subnet configuration
  ip_range  = var.ip_range
  subnet_id = var.subnet_id

  ## Private Endpoint configuration
  private_endpoint_enabled                  = var.private_endpoint_config.enabled
  private_endpoint_cassandra_name           = var.private_endpoint_config.name_cassandra
  private_endpoint_mongo_name               = var.private_endpoint_config.name_mongo
  private_endpoint_sql_name                 = var.private_endpoint_config.name_sql
  private_endpoint_table_name               = var.private_endpoint_config.name_table
  private_service_connection_cassandra_name = var.private_endpoint_config.service_connection_name_cassandra
  private_service_connection_mongo_name     = var.private_endpoint_config.service_connection_name_mongo
  private_service_connection_sql_name       = var.private_endpoint_config.service_connection_name_sql
  private_dns_zone_cassandra_ids            = var.private_endpoint_config.private_dns_zone_cassandra_ids
  private_dns_zone_mongo_ids                = var.private_endpoint_config.private_dns_zone_mongo_ids
  private_dns_zone_sql_ids                  = var.private_endpoint_config.private_dns_zone_sql_ids
  private_dns_zone_table_ids                = var.private_endpoint_config.private_dns_zone_table_ids

  # 8. Metadata
  tags = var.tags
}
