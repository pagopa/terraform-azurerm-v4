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

output "high_availability_enabled" {
  value       = module.managed_redis.high_availability_enabled
  description = "Whether high availability is enabled."
}

output "private_endpoint_id" {
  value       = module.managed_redis.private_endpoint_id
  description = "The ID of the private endpoint (if enabled)."
}

output "primary_access_key" {
  value     = module.managed_redis.primary_access_key
  sensitive = true
}

output "secondary_access_key" {
  value     = module.managed_redis.secondary_access_key
  sensitive = true
}

output "primary_connection_url" {
  value       = module.managed_redis.primary_connection_url
  sensitive   = true
  description = "The primary connection URL for the managed Redis instance."
}

output "secondary_connection_url" {
  value       = module.managed_redis.secondary_connection_string
  sensitive   = true
  description = "The secondary connection URL for the managed Redis instance."
}

output "port" {
  value = module.managed_redis.port
}