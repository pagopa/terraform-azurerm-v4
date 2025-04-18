output "namespace_id" {
  description = "Id of Event Hub Namespace."
  value       = azurerm_eventhub_namespace.this.id
}

output "hub_ids" {
  description = "Map of hubs and their ids."
  value       = { for k, v in azurerm_eventhub.events : k => v.id }
}

output "key_ids" {
  description = "List of key ids."
  value       = local.keys
}

output "name" {
  description = "The name of this Event Hub"
  value       = azurerm_eventhub_namespace.this.name
}

output "resource_group_name" {
  value = azurerm_eventhub_namespace.this.resource_group_name
}

output "keys" {
  description = "Map of hubs with keys => primary_key / secondary_key mapping."
  sensitive   = true
  value = { for k, h in azurerm_eventhub_authorization_rule.events : k => {
    primary_key                 = h.primary_key
    primary_connection_string   = h.primary_connection_string
    secondary_key               = h.secondary_key
    secondary_connection_string = h.secondary_connection_string
    }
  }
}
