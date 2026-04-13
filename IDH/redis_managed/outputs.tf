#
# Managed Redis Resource Information
#
output "id" {
  value       = module.redis_managed.id
  description = "The ID of the Managed Redis."
}

output "name" {
  value       = module.redis_managed.name
  description = "The name of the Managed Redis."
}

output "location" {
  value       = module.redis_managed.location
  description = "The Azure region."
}

output "resource_group_name" {
  value       = module.redis_managed.resource_group_name
  description = "The resource group name."
}

output "sku_name" {
  value       = module.redis_managed.sku_name
  description = "The SKU name (Enterprise_E10, Enterprise_E20, etc)."
}

#
# Private Endpoint Information
#
output "private_endpoint_id" {
  value       = module.redis_managed.private_endpoint_id
  description = "The ID of the private endpoint (if enabled)."
}

output "private_endpoint_name" {
  value       = module.redis_managed.private_endpoint_name
  description = "The name of the private endpoint (if enabled)."
}

#
# Monitoring and Alerting Information
#
output "action_group_id" {
  value       = module.redis_managed.action_group_id
  description = "The ID of the action group for Redis alerts (if enabled)."
}

output "action_group_name" {
  value       = module.redis_managed.action_group_name
  description = "The name of the action group for Redis alerts (if enabled)."
}

output "metric_alert_cpu_id" {
  value       = module.redis_managed.metric_alert_cpu_id
  description = "The ID of the high CPU metric alert (if enabled)."
}

output "metric_alert_memory_id" {
  value       = module.redis_managed.metric_alert_memory_id
  description = "The ID of the high memory metric alert (if enabled)."
}

output "metric_alert_evictions_id" {
  value       = module.redis_managed.metric_alert_evictions_id
  description = "The ID of the high evictions metric alert (if enabled)."
}

output "metric_alert_connections_id" {
  value       = module.redis_managed.metric_alert_connections_id
  description = "The ID of the connection failures metric alert (if enabled)."
}
