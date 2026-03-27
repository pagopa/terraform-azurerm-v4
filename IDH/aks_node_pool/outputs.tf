output "id" {
  value = module.aks_node_pool.id
}

output "name" {
  value = module.aks_node_pool.name
}

output "subnet_id" {
  value = var.embedded_subnet.enabled ? module.aks_overlay_snet.id : var.vnet_subnet_id
}

output "subnet_name" {
  value = var.embedded_subnet.enabled ? module.aks_overlay_snet.subnet_name : ""
}

output "subnet_b_id" {
  value = ""
}
