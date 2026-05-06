output "resource_alerts" {
  description = "Map di tutti gli azurerm_monitor_metric_alert creati, indicizzati per '{resource_name}-{metric_name}'."
  value       = azurerm_monitor_metric_alert.this
}

output "action_groups" {
  description = "Map di tutti gli action group risolti, indicizzati per '{resource_name}-{metric_name}-{action_group_name}'."
  value       = data.azurerm_monitor_action_group.this
}

output "resource_metric_map" {
  description = "Lista piatta di tutte le combinazioni risorsa × metrica elaborate dal modulo. Utile per debug."
  value       = local.resource_metric_map
}
