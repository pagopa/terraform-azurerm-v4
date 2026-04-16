output "id" {
  value       = azurerm_managed_redis.this.id
  description = "The ID of the managed Redis instance."
}

output "name" {
  value       = azurerm_managed_redis.this.name
  description = "The name of the managed Redis instance."
}

output "location" {
  value       = azurerm_managed_redis.this.location
  description = "The Azure location of the managed Redis instance."
}

output "resource_group_name" {
  value       = azurerm_managed_redis.this.resource_group_name
  description = "The resource group name of the managed Redis instance."
}

output "hostname" {
  value       = azurerm_managed_redis.this.hostname
  description = "The hostname of the managed Redis instance."
}

output "sku_name" {
  value       = var.sku_name
  description = "The SKU name of the managed Redis instance."
}

output "high_availability_enabled" {
  value       = var.high_availability_enabled
  description = "Whether high availability is enabled."
}

output "public_network_access" {
  value       = var.public_network_access
  description = "The public network access setting."
}

output "private_endpoint_id" {
  value       = try(azurerm_private_endpoint.this[0].id, null)
  description = "The ID of the private endpoint (if enabled)."
}

output "private_endpoint_network_interface_ids" {
  value       = try(azurerm_private_endpoint.this[0].custom_dns_configs[*].ip_address, [])
  description = "The IP addresses assigned to the private endpoint."
}
