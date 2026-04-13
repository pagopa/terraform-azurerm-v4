module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "redis_managed"
}

locals {
  # Generate a normalized name for the Redis cache
  redis_name = format(
    "%s%sredis%s",
    var.product_name,
    var.env,
    var.idh_resource_tier
  )
}

# Call the v4 redis_managed module with IDH-provided configuration
module "redis_managed" {
  source = "../../redis_managed"

  name                = local.redis_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # SKU configuration from IDH
  sku_name            = module.idh_loader.idh_resource_configuration.sku_name
  family              = module.idh_loader.idh_resource_configuration.family
  capacity            = module.idh_loader.idh_resource_configuration.capacity
  redis_version       = try(module.idh_loader.idh_resource_configuration.redis_version, "7")

  # Optional configurations with IDH defaults
  enable_non_ssl_port           = try(module.idh_loader.idh_resource_configuration.enable_non_ssl_port, false)
  minimum_tls_version           = try(module.idh_loader.idh_resource_configuration.minimum_tls_version, "1.2")
  shard_count                   = try(module.idh_loader.idh_resource_configuration.shard_count, 1)
  subnet_id                     = try(module.idh_loader.idh_resource_configuration.subnet_id, null)
  private_static_ip_address     = try(module.idh_loader.idh_resource_configuration.private_static_ip_address, null)
  public_network_access_enabled = try(module.idh_loader.idh_resource_configuration.public_network_access_enabled, false)
  custom_zones                  = try(module.idh_loader.idh_resource_configuration.custom_zones, [1, 2, 3])
  enable_authentication         = try(module.idh_loader.idh_resource_configuration.enable_authentication, true)

  # Private endpoint and alerting configuration
  private_endpoint_enabled          = try(module.idh_loader.idh_resource_configuration.private_endpoint_enabled, var.private_endpoint_enabled)
  private_endpoint_subnet_id        = try(module.idh_loader.idh_resource_configuration.private_endpoint_subnet_id, var.private_endpoint_subnet_id)
  private_endpoint_name             = try(module.idh_loader.idh_resource_configuration.private_endpoint_name, var.private_endpoint_name)
  action_group_enabled              = try(module.idh_loader.idh_resource_configuration.action_group_enabled, var.action_group_enabled)
  action_group_name                 = try(module.idh_loader.idh_resource_configuration.action_group_name, null)
  alert_email_receivers             = try(module.idh_loader.idh_resource_configuration.alert_email_receivers, var.alert_email_receivers)
  alert_high_cpu_threshold          = try(module.idh_loader.idh_resource_configuration.alert_high_cpu_threshold, var.alert_high_cpu_threshold)
  alert_high_memory_threshold       = try(module.idh_loader.idh_resource_configuration.alert_high_memory_threshold, var.alert_high_memory_threshold)
  alert_eviction_threshold          = try(module.idh_loader.idh_resource_configuration.alert_eviction_threshold, var.alert_eviction_threshold)
  alert_connection_failures_threshold = try(module.idh_loader.idh_resource_configuration.alert_connection_failures_threshold, var.alert_connection_failures_threshold)

  tags = var.tags
}

