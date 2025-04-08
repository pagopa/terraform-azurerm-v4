output "resource_groups" {
  description = "Map of all created resource groups with their properties"
  value       = azurerm_resource_group.resource_groups
}

output "resource_group_names" {
  description = "Map of resource group names"
  value       = local.all_resource_groups
}
