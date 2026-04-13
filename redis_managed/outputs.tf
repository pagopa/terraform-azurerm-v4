#
# Managed Redis Resource Information
#
output "id" {
  value       = azurerm_managed_redis.this.id
  description = "The ID of the Managed Redis."
}

output "name" {
  value       = azurerm_managed_redis.this.name
  description = "The name of the Managed Redis."
}

output "location" {
  value       = azurerm_managed_redis.this.location
  description = "The Azure region."
}

output "resource_group_name" {
  value       = azurerm_managed_redis.this.resource_group_name
  description = "The resource group name."
}

output "sku_name" {
  value       = azurerm_managed_redis.this.sku_name
  description = "The SKU name (Enterprise_E10, Enterprise_E20, etc)."
}

#
# Private Endpoint Information
#
output "private_endpoint_id" {
  value       = try(azurerm_private_endpoint.redis[0].id, null)
  description = "The ID of the private endpoint (if enabled)."
}

output "private_endpoint_name" {
  value       = try(azurerm_private_endpoint.redis[0].name, null)
  description = "The name of the private endpoint (if enabled)."
}

#
# Monitoring and Alerting Information
#
output "action_group_id" {
  value       = try(azurerm_monitor_action_group.redis_alerts[0].id, null)
  description = "The ID of the action group for Redis alerts (if enabled)."
}

output "action_group_name" {
  value       = try(azurerm_monitor_action_group.redis_alerts[0].name, null)
  description = "The name of the action group for Redis alerts (if enabled)."
}

output "metric_alert_cpu_id" {
  value       = try(azurerm_monitor_metric_alert.redis_high_cpu[0].id, null)
  description = "The ID of the high CPU metric alert (if enabled)."
}

output "metric_alert_memory_id" {
  value       = try(azurerm_monitor_metric_alert.redis_high_memory[0].id, null)
  description = "The ID of the high memory metric alert (if enabled)."
}

output "metric_alert_evictions_id" {
  value       = try(azurerm_monitor_metric_alert.redis_high_evictions[0].id, null)
  description = "The ID of the high evictions metric alert (if enabled)."
}

output "metric_alert_connections_id" {
  value       = try(azurerm_monitor_metric_alert.redis_connection_failures[0].id, null)
  description = "The ID of the connection failures metric alert (if enabled)."
}
