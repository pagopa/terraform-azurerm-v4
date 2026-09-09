

output "subnet_id" {
  value       = var.embedded_subnet.enabled ? module.aks_overlay_snet[0].id : var.vnet_subnet_id
  description = "ID of the subnet associated with the AKS node pool. If embedded_subnet is enabled, the ID of the overlay subnet is returned, otherwise the ID of the provided virtual network subnet is returned."
}

output "subnet_name" {
  value       = var.embedded_subnet.enabled ? module.aks_overlay_snet[0].subnet_name : ""
  description = "Name of the subnet associated with the AKS node pool. If embedded_subnet is enabled, the name of the overlay subnet is returned, otherwise an empty string is returned since the subnet name is not directly available when using an external subnet."
}


