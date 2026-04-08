output "id" {
  value = azurerm_managed_redis.this.id
}

output "name" {
  value = azurerm_managed_redis.this.name
}

output "location" {
  value = azurerm_managed_redis.this.location
}

output "resource_group_name" {
  value = azurerm_managed_redis.this.resource_group_name
}

output "hostname" {
  value = azurerm_managed_redis.this.hostname
}

output "port" {
  value = azurerm_managed_redis.this.default_database[0].port
}

output "sku_name" {
  value = var.sku_name
}

#
# Access Keys
#
output "primary_access_key" {
  value     = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive = true
}

output "secondary_access_key" {
  value     = azurerm_managed_redis.this.default_database[0].secondary_access_key
  sensitive = true
}

output "primary_connection_url" {
  value     = "rediss://:${azurerm_managed_redis.this.default_database[0].primary_access_key}@${azurerm_managed_redis.this.hostname}:${azurerm_managed_redis.this.default_database[0].port}"
  sensitive = true
}

output "secondary_connection_url" {
  value     = "rediss://:${azurerm_managed_redis.this.default_database[0].secondary_access_key}@${azurerm_managed_redis.this.hostname}:${azurerm_managed_redis.this.default_database[0].port}"
  sensitive = true
}
