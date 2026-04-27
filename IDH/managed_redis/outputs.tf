output "id" {
  value       = module.managed_redis.id
  description = "The resource ID of the managed Redis instance."
}

output "name" {
  value       = module.managed_redis.name
  description = "The name of the managed Redis instance."
}

output "location" {
  value       = module.managed_redis.location
  description = "The Azure location of the managed Redis instance."
}

output "resource_group_name" {
  value       = module.managed_redis.resource_group_name
  description = "The resource group name of the managed Redis instance."
}

output "hostname" {
  value       = module.managed_redis.hostname
  description = "The hostname of the managed Redis instance."
}

output "sku_name" {
  value       = module.managed_redis.sku_name
  description = "The SKU name of the managed Redis instance."
}

output "high_availability_enabled" {
  value       = module.managed_redis.high_availability_enabled
  description = "Whether high availability is enabled."
}

output "public_network_access" {
  value       = module.managed_redis.public_network_access
  description = "The public network access setting."
}

output "private_endpoint_id" {
  value       = module.managed_redis.private_endpoint_id
  description = "The ID of the private endpoint (if enabled)."
}

output "private_endpoint_network_interface_ids" {
  value       = module.managed_redis.private_endpoint_network_interface_ids
  description = "The IP addresses assigned to the private endpoint."
}

output "private_endpoint_subnet_id" {
  value       = var.embedded_subnet.enabled && module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? module.private_endpoint_snet[0].subnet_id : var.private_endpoint_subnet_id
  description = "The subnet ID used for the private endpoint."
}

