module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "managed_redis"
}

locals {
  # Runtime overrides - allow users to override specific tier defaults
  eviction_policy            = var.eviction_policy_override != null ? var.eviction_policy_override : module.idh_loader.idh_resource_configuration.eviction_policy
  geo_replication_group_name = var.geo_replication.enabled ? "${var.name}-geo-replication-group" : null
}

# ---------------------------------------------------
# Managed Redis Instance (Primary)
# ---------------------------------------------------
module "managed_redis" {
  source = "../../managed_redis"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                  = module.idh_loader.idh_resource_configuration.sku_name
  high_availability_enabled = module.idh_loader.idh_resource_configuration.high_availability_enabled
  public_network_access     = module.idh_loader.idh_resource_configuration.public_network_access

  access_keys_authentication_enabled = module.idh_loader.idh_resource_configuration.access_keys_authentication_enabled
  client_protocol                    = module.idh_loader.idh_resource_configuration.client_protocol
  clustering_policy                  = module.idh_loader.idh_resource_configuration.clustering_policy
  eviction_policy                    = local.eviction_policy

  # Persistence configuration
  persistence_configuration = module.idh_loader.idh_resource_configuration.persistence_configuration

  # Modules support
  modules = coalesce(var.modules_override, module.idh_loader.idh_resource_configuration.modules)

  # Customer-managed key encryption (optional)
  customer_managed_key_config = var.customer_managed_key_config

  # Private endpoint configuration
  private_endpoint_enabled   = module.idh_loader.idh_resource_configuration.private_endpoint_enabled
  private_endpoint_subnet_id = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? module.private_endpoint_snet[0].subnet_id : var.private_endpoint_subnet_id) : null
  private_dns_zone_ids       = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? var.embedded_subnet.private_dns_zone_ids : var.private_dns_zone_ids) : []

  # Geo-replication
  geo_replication_group_name = local.geo_replication_group_name

  # Monitoring and alerts
  alert_action_group_ids   = var.alert_action_group_ids
  cpu_alert_enabled        = module.idh_loader.idh_resource_configuration.cpu_alert_enabled
  cpu_threshold            = module.idh_loader.idh_resource_configuration.cpu_threshold
  memory_alert_enabled     = module.idh_loader.idh_resource_configuration.memory_alert_enabled
  memory_threshold         = module.idh_loader.idh_resource_configuration.memory_threshold
  eviction_alert_enabled   = module.idh_loader.idh_resource_configuration.eviction_alert_enabled
  eviction_threshold       = module.idh_loader.idh_resource_configuration.eviction_threshold
  connection_alert_enabled = module.idh_loader.idh_resource_configuration.connection_alert_enabled
  connection_threshold     = module.idh_loader.idh_resource_configuration.connection_threshold

  tags = var.tags
}

# ---------------------------------------------------
# Embedded Subnet - Private Endpoint (Primary)
# ---------------------------------------------------
module "private_endpoint_snet" {
  count = var.embedded_subnet.enabled && module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? 1 : 0

  source            = "../subnet"
  env               = var.env
  idh_resource_tier = "slash28_privatelink_true"
  product_name      = var.product_name

  name                 = "${var.name}-pe-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  custom_nsg_configuration = {
    source_address_prefixes      = var.embedded_nsg_configuration.source_address_prefixes
    source_address_prefixes_name = var.embedded_nsg_configuration.source_address_prefixes_name
    target_service               = "managedredis"
  }
  resource_group_nsg_name    = var.resource_group_nsg_name
  nsg_flow_log_configuration = var.nsg_flow_log_configuration
  tags                       = var.tags
}

# ---------------------------------------------------
# Managed Redis Instance (Replica)
# ---------------------------------------------------
module "managed_redis_replica" {
  source = "../../managed_redis"
  count  = var.geo_replication.enabled && module.idh_loader.idh_resource_configuration.geo_replication_allowed ? 1 : 0

  name                = "${var.name}-replica"
  location            = var.geo_replication.location
  resource_group_name = var.resource_group_name

  sku_name                  = module.idh_loader.idh_resource_configuration.sku_name
  high_availability_enabled = module.idh_loader.idh_resource_configuration.high_availability_enabled
  public_network_access     = module.idh_loader.idh_resource_configuration.public_network_access

  access_keys_authentication_enabled = module.idh_loader.idh_resource_configuration.access_keys_authentication_enabled
  client_protocol                    = module.idh_loader.idh_resource_configuration.client_protocol
  clustering_policy                  = module.idh_loader.idh_resource_configuration.clustering_policy
  eviction_policy                    = local.eviction_policy

  # Persistence configuration
  persistence_configuration = module.idh_loader.idh_resource_configuration.persistence_configuration

  # Modules support
  modules = coalesce(var.modules_override, module.idh_loader.idh_resource_configuration.modules)

  # Customer-managed key encryption (optional)
  customer_managed_key_config = var.customer_managed_key_config

  # Private endpoint configuration
  private_endpoint_enabled   = module.idh_loader.idh_resource_configuration.private_endpoint_enabled
  private_endpoint_subnet_id = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? module.private_endpoint_replica_snet[0].subnet_id : var.geo_replication.subnet_id) : null
  private_dns_zone_ids       = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? var.embedded_subnet.private_dns_zone_ids : var.geo_replication.private_dns_zone_ids) : []

  # Geo-replication
  geo_replication_group_name = local.geo_replication_group_name

  # Monitoring and alerts
  alert_action_group_ids   = var.alert_action_group_ids
  cpu_alert_enabled        = module.idh_loader.idh_resource_configuration.cpu_alert_enabled
  cpu_threshold            = module.idh_loader.idh_resource_configuration.cpu_threshold
  memory_alert_enabled     = module.idh_loader.idh_resource_configuration.memory_alert_enabled
  memory_threshold         = module.idh_loader.idh_resource_configuration.memory_threshold
  eviction_alert_enabled   = module.idh_loader.idh_resource_configuration.eviction_alert_enabled
  eviction_threshold       = module.idh_loader.idh_resource_configuration.eviction_threshold
  connection_alert_enabled = module.idh_loader.idh_resource_configuration.connection_alert_enabled
  connection_threshold     = module.idh_loader.idh_resource_configuration.connection_threshold

  tags = var.tags
}

# ---------------------------------------------------
# Embedded Subnet - Private Endpoint (Replica)
# ---------------------------------------------------
module "private_endpoint_replica_snet" {
  count = var.embedded_subnet.enabled && var.geo_replication.enabled ? 1 : 0

  source            = "../subnet"
  env               = var.env
  idh_resource_tier = "slash28_privatelink_true"
  product_name      = var.product_name

  name                 = "${var.name}-pe-replica-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  custom_nsg_configuration = {
    source_address_prefixes      = var.embedded_nsg_configuration.source_address_prefixes
    source_address_prefixes_name = var.embedded_nsg_configuration.source_address_prefixes_name
    target_service               = "managedredis"
  }
  resource_group_nsg_name    = var.resource_group_nsg_name
  nsg_flow_log_configuration = var.nsg_flow_log_configuration
  tags                       = var.tags
}

resource "azurerm_managed_redis_geo_replication" "this" {
  count = var.geo_replication.enabled && module.idh_loader.idh_resource_configuration.geo_replication_allowed ? 1 : 0

  managed_redis_id = module.managed_redis.id

  linked_managed_redis_ids = [
    module.managed_redis_replica[0].id
  ]
}
