output "id" {
  value = azurerm_redis_cache.this.id
}

output "name" {
  value = azurerm_redis_cache.this.name
}

output "location" {
  value = azurerm_redis_cache.this.location
}

output "resource_group_name" {
  value = azurerm_redis_cache.this.resource_group_name
}

output "hostname" {
  value = azurerm_redis_cache.this.hostname
}

output "port" {
  value = azurerm_redis_cache.this.port
}

output "ssl_port" {
  value = azurerm_redis_cache.this.ssl_port
}

output "sku" {
  value = var.sku_name
}

#
# Access Keys
#
output "primary_access_key" {
  value     = azurerm_redis_cache.this.primary_access_key
  sensitive = true
}

output "primary_connection_string" {
  value     = azurerm_redis_cache.this.primary_connection_string
  sensitive = true
}

output "primary_connection_url" {
  value     = "rediss://:${azurerm_redis_cache.this.primary_access_key}@${azurerm_redis_cache.this.hostname}:${azurerm_redis_cache.this.ssl_port}"
  sensitive = true
}

output "secondary_access_key" {
  value     = azurerm_redis_cache.this.secondary_access_key
  sensitive = true
}

output "secondary_connection_string" {
  value     = azurerm_redis_cache.this.secondary_connection_string
  sensitive = true
}

output "secondary_connection_url" {
  value     = "rediss://:${azurerm_redis_cache.this.secondary_access_key}@${azurerm_redis_cache.this.hostname}:${azurerm_redis_cache.this.ssl_port}"
  sensitive = true
}
