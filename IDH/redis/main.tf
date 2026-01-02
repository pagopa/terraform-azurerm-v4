module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "redis"
}

locals {
  capacity = var.capacity != null ? var.capacity : module.idh_loader.idh_resource_configuration.capacity
}

resource "terraform_data" "validation" {
  input = timestamp()

  lifecycle {
    precondition {
      condition     = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? var.private_endpoint == null : var.private_endpoint != null) : true
      error_message = "private_endpoint must be null when embedded_subnet is enabled, otherwise it must be defined for resource '${var.idh_resource_tier}' on env '${var.env}'"
    }

  }
}


# IDH/subnet
module "private_endpoint_snet" {
  count                = var.embedded_subnet.enabled && module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? 1 : 0
  source               = "../subnet"
  depends_on           = [terraform_data.validation]
  name                 = "${var.name}-pe-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  env               = var.env
  idh_resource_tier = "slash28_privatelink_true"
  product_name      = var.product_name

  custom_nsg_configuration = {
    source_address_prefixes      = var.embedded_nsg_configuration.source_address_prefixes
    source_address_prefixes_name = var.embedded_nsg_configuration.source_address_prefixes_name
    target_service               = "redis"
  }
  nsg_flow_log_configuration = var.nsg_flow_log_configuration
  tags                       = var.tags
}

# -----------------------------------------------
# Redis Cache
# -----------------------------------------------
module "redis" {
  source     = "../../redis_cache"
  depends_on = [terraform_data.validation]

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  capacity                      = local.capacity
  enable_non_ssl_port           = module.idh_loader.idh_resource_configuration.enable_non_ssl_port
  family                        = module.idh_loader.idh_resource_configuration.family
  sku_name                      = module.idh_loader.idh_resource_configuration.sku_name
  enable_authentication         = module.idh_loader.idh_resource_configuration.enable_authentication
  redis_version                 = module.idh_loader.idh_resource_configuration.version
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  custom_zones                  = module.idh_loader.idh_resource_configuration.zones
  shard_count                   = lookup(module.idh_loader.idh_resource_configuration, "shard_count", null)

  backup_configuration = lookup(module.idh_loader.idh_resource_configuration, "backup_configuration", null) != null ? {
    frequency                 = module.idh_loader.idh_resource_configuration.backup_configuration.frequency
    max_snapshot_count        = module.idh_loader.idh_resource_configuration.backup_configuration.max_snapshot_count
    storage_connection_string = module.idh_loader.idh_resource_configuration.backup_configuration.storage_connection_string
  } : null
  data_persistence_authentication_method = module.idh_loader.idh_resource_configuration.data_persistence_authentication_method

  private_static_ip_address = module.idh_loader.idh_resource_configuration.subnet_integration ? var.private_static_ip_address : null
  subnet_id                 = module.idh_loader.idh_resource_configuration.subnet_integration ? var.subnet_id : null


  private_endpoint = {
    enabled              = module.idh_loader.idh_resource_configuration.private_endpoint_enabled
    subnet_id            = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? module.private_endpoint_snet[0].subnet_id : var.private_endpoint.subnet_id) : ""
    private_dns_zone_ids = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? (var.embedded_subnet.enabled ? var.embedded_subnet.private_dns_zone_ids : var.private_endpoint.private_dns_zone_ids) : []
  }

  patch_schedules = coalesce(var.patch_schedules, module.idh_loader.idh_resource_configuration.patch_schedule)

  tags = var.tags


}


# -----------------------------------------------
# Alerts
# -----------------------------------------------

resource "azurerm_monitor_metric_alert" "redis_cache_used_memory_exceeded" {
  count = module.idh_loader.idh_resource_configuration.alert_enabled ? 1 : 0

  name                = "[${module.redis.name}] Used Memory close to the threshold"
  resource_group_name = var.resource_group_name
  scopes              = [module.redis.id]
  description         = "The amount of cache memory in MB that is used for key/value pairs in the cache during the specified reporting interval, this amount is close to 200 MB so close to the threshold (250 MB)"
  severity            = 0
  window_size         = "PT5M"
  frequency           = "PT5M"
  auto_mitigate       = false

  target_resource_type     = "Microsoft.Cache/redis"
  target_resource_location = var.location

  # Metric info
  # https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-supported#microsoftdocumentdbdatabaseaccounts
  criteria {
    metric_namespace       = "Microsoft.Cache/redis"
    metric_name            = "usedmemorypercentage"
    aggregation            = "Maximum"
    operator               = "GreaterThan"
    threshold              = "90"
    skip_metric_validation = false
  }

  dynamic "action" {
    for_each = toset(var.alert_action_group_ids)
    iterator = ag_id
    content {
      action_group_id = ag_id.value
    }
  }

  tags = var.tags
}

