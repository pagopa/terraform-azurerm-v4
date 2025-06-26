output "id" {
  value = try(azurerm_kubernetes_cluster_node_pool.this.id, null)
}

output "name" {
  value = try(azurerm_kubernetes_cluster_node_pool.this.name, null)
}
