module "idh_loader" {
  source = "../01_idh_loader"

  product_name       = var.product_name
  env          = var.env
  idh_resource_tier = var.idh_resource
  idh_resource_type = "redis"
}

module "redis" {
  source = "../../redis_cache"

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  capacity                      = module.idh_loader.idh_config.capacity
  enable_non_ssl_port           = module.idh_loader.idh_config.enable_non_ssl_port
  family                        = module.idh_loader.idh_config.family
  sku_name                      = module.idh_loader.idh_config.sku_name
  enable_authentication         = module.idh_loader.idh_config.enable_authentication
  redis_version                 = module.idh_loader.idh_config.version
  public_network_access_enabled = module.idh_loader.idh_config.public_network_access_enabled
  custom_zones                  = module.idh_loader.idh_config.zones
  shard_count                   = lookup(module.idh_loader.idh_config, "shard_count", null)

  backup_configuration = lookup(module.idh_loader.idh_config, "backup_configuration", null) != null ? {
    frequency                 = module.idh_loader.idh_config.backup_configuration.frequency
    max_snapshot_count        = module.idh_loader.idh_config.backup_configuration.max_snapshot_count
    storage_connection_string = module.idh_loader.idh_config.backup_configuration.storage_connection_string
  } : null
  data_persistence_authentication_method = module.idh_loader.idh_config.data_persistence_authentication_method

  private_static_ip_address = module.idh_loader.idh_config.subnet_integration ? var.private_static_ip_address : null
  subnet_id                 = module.idh_loader.idh_config.subnet_integration ? var.subnet_id : null


  private_endpoint = {
    enabled              = module.idh_loader.idh_config.private_endpoint_enabled
    subnet_id            = module.idh_loader.idh_config.private_endpoint_enabled ? var.private_endpoint.subnet_id : ""
    private_dns_zone_ids = module.idh_loader.idh_config.private_endpoint_enabled ? var.private_endpoint.private_dns_zone_ids : []
  }

  patch_schedules = coalesce(var.patch_schedules, module.idh_loader.idh_config.patch_schedule)

  tags = var.tags
}


# -----------------------------------------------
# Alerts
# -----------------------------------------------

resource "azurerm_monitor_metric_alert" "redis_cache_used_memory_exceeded" {
  count = module.idh_loader.idh_config.alert_enabled ? 1 : 0

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

