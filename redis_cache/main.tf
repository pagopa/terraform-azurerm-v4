resource "azurerm_redis_cache" "this" {
  name                 = var.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  non_ssl_port_enabled = var.enable_non_ssl_port
  minimum_tls_version  = "1.2"

  capacity      = var.capacity
  family        = var.family
  sku_name      = var.sku_name
  redis_version = var.redis_version
  shard_count   = var.shard_count

  subnet_id                     = var.subnet_id
  private_static_ip_address     = var.private_static_ip_address
  public_network_access_enabled = var.public_network_access_enabled
  zones                         = var.custom_zones

  redis_configuration {
    authentication_enabled = var.enable_authentication

    rdb_backup_enabled            = var.backup_configuration != null
    rdb_backup_frequency          = var.backup_configuration != null ? var.backup_configuration.frequency : null
    rdb_backup_max_snapshot_count = var.backup_configuration != null ? var.backup_configuration.max_snapshot_count : null
    rdb_storage_connection_string = var.backup_configuration != null ? var.backup_configuration.storage_connection_string : null

    data_persistence_authentication_method = var.data_persistence_authentication_method
  }

  dynamic "patch_schedule" {
    for_each = var.patch_schedules
    iterator = schedule
    content {
      day_of_week    = schedule.value.day_of_week
      start_hour_utc = schedule.value.start_hour_utc
    }
  }

  tags = var.tags

  # NOTE: There's a bug in the Redis API where the original storage connection string isn't being returned,
  # which is being tracked here [https://github.com/Azure/azure-rest-api-specs/issues/3037].
  # In the interim we use the ignore_changes attribute to ignore changes to this field.
  lifecycle {
    ignore_changes = [redis_configuration[0].rdb_storage_connection_string]
  }
}

#
# 🌐 Network
#
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint.enabled ? 1 : 0

  name                = "${azurerm_redis_cache.this.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_dns_zone_group {
    name                 = "${azurerm_redis_cache.this.name}-private-dns-zone-group"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "${azurerm_redis_cache.this.name}-private-service-connection"
    private_connection_resource_id = azurerm_redis_cache.this.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  tags = var.tags
}
