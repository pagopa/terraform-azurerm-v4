locals {
  current_node_counts = { for p in data.azurerm_kubernetes_cluster.this.agent_pool_profile : p.name => p.count }
  cluster_id_parts    = split("/", var.kubernetes_cluster_id)
  cluster_name        = local.cluster_id_parts[8]
  cluster_rg_name     = local.cluster_id_parts[4]
}
