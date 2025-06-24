output "id" {
  value = try(azurerm_kubernetes_cluster_node_pool.this.id, null)
}

output "name" {
  value = try(azurerm_kubernetes_cluster_node_pool.this.name, null)
}

output "node_resource_group" {
  value = try(azurerm_kubernetes_cluster_node_pool.this.node_resource_group, null)
}
