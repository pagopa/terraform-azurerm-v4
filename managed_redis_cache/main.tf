resource "azurerm_managed_redis" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                  = var.sku_name
  zones                     = var.zones
  high_availability_enabled = var.high_availability_enabled
  public_network_access     = var.public_network_access

  default_database {
    access_keys_authentication_enabled            = var.default_database.access_keys_authentication_enabled
    client_protocol                               = var.default_database.client_protocol
    clustering_policy                             = var.default_database.clustering_policy
    eviction_policy                               = var.default_database.eviction_policy
    persistence_redis_database_backup_frequency   = var.default_database.persistence_rdb_frequency
    persistence_append_only_file_backup_frequency = var.default_database.persistence_aof_frequency
  }

  tags = var.tags
}

#
# 🌐 Network
#
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint.enabled ? 1 : 0

  name                = "${azurerm_managed_redis.this.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_dns_zone_group {
    name                 = "${azurerm_managed_redis.this.name}-private-dns-zone-group"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "${azurerm_managed_redis.this.name}-private-service-connection"
    private_connection_resource_id = azurerm_managed_redis.this.id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  tags = var.tags
}
