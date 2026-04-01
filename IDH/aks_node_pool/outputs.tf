output "id" {
  value       = module.aks_node_pool_foo.id
  description = "ID of the AKS node pool. Deprecated in favor of node_pool_ids output, which returns a list of node pool IDs to accommodate multiple node pools when double_node_pool is enabled."
}

output "name" {
  value       = module.aks_node_pool_foo.name
  description = "Name of the AKS node pool. Deprecated in favor of node_pool_names output, which returns a list of node pool names to accommodate multiple node pools when double_node_pool is enabled."
}

output "node_pool_ids" {
  value       = var.double_node_pool.enabled ? [module.aks_node_pool_foo.id, module.aks_node_pool_bar[0].id] : [module.aks_node_pool_foo.id]
  description = "List of AKS node pool IDs. If double_node_pool is enabled, both node pool IDs are returned, otherwise only the first node pool ID is returned."
}

output "node_pool_names" {
  value       = var.double_node_pool.enabled ? [module.aks_node_pool_foo.name, module.aks_node_pool_bar[0].name] : [module.aks_node_pool_foo.name]
  description = "List of AKS node pool names. If double_node_pool is enabled, both node pool names are returned, otherwise only the first node pool name is returned."
}

output "subnet_id" {
  value       = var.embedded_subnet.enabled ? module.aks_overlay_snet.id : var.vnet_subnet_id
  description = "ID of the subnet associated with the AKS node pool. If embedded_subnet is enabled, the ID of the overlay subnet is returned, otherwise the ID of the provided virtual network subnet is returned."
}

output "subnet_name" {
  value       = var.embedded_subnet.enabled ? module.aks_overlay_snet.subnet_name : ""
  description = "Name of the subnet associated with the AKS node pool. If embedded_subnet is enabled, the name of the overlay subnet is returned, otherwise an empty string is returned since the subnet name is not directly available when using an external subnet."
}


