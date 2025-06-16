output "namespace_id" {
  description = "Id of Event Hub Namespace."
  value       = module.event_hub.namespace_id
}

output "name" {
  description = "The name of this Event Hub"
  value       = module.event_hub.name
}

output "resource_group_name" {
  value = module.event_hub.resource_group_name
}
