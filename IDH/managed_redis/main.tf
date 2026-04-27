module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "managed_redis"
}

locals {
  # Runtime overrides - allow users to override specific tier defaults
  client_protocol = var.client_protocol_override != null ? var.client_protocol_override : module.idh_loader.idh_resource_configuration.client_protocol
  eviction_policy = var.eviction_policy_override != null ? var.eviction_policy_override : module.idh_loader.idh_resource_configuration.eviction_policy
}

# IDH/subnet - optional embedded subnet for private endpoint
module "private_endpoint_snet" {
  count             = var.embedded_subnet.enabled && module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? 1 : 0
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
# Managed Redis Instance
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
  client_protocol                    = local.client_protocol
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

  # Monitoring and alerts
  alert_action_group_ids            = var.alert_action_group_ids
  enable_cpu_alerts                 = module.idh_loader.idh_resource_configuration.enable_cpu_alerts
  cpu_usage_percentage_threshold    = module.idh_loader.idh_resource_configuration.cpu_usage_percentage_threshold
  enable_memory_alerts              = module.idh_loader.idh_resource_configuration.enable_memory_alerts
  memory_usage_percentage_threshold = module.idh_loader.idh_resource_configuration.memory_usage_percentage_threshold
  enable_eviction_alerts            = module.idh_loader.idh_resource_configuration.enable_eviction_alerts
  enable_connection_alerts          = module.idh_loader.idh_resource_configuration.enable_connection_alerts
  connection_count_threshold        = module.idh_loader.idh_resource_configuration.connection_count_threshold

  tags = var.tags
}

