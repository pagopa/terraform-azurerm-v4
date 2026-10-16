locals {
  cluster_id_parts    = split("/", var.kubernetes_cluster_id)
  cluster_name        = local.cluster_id_parts[8]
  cluster_rg_name     = local.cluster_id_parts[4]
  node_pool_foo_name  = var.double_node_pool.enabled ? "${var.name}foo" : var.name
  node_pool_bar_name  = "${var.name}bar"
  current_node_counts = { for p in data.azurerm_kubernetes_cluster.this.agent_pool_profile : p.name => p.count }

  predefined_node_labels = {
    non_core = {
      "critical" = "false"
    }
  }

  predefined_node_taints = {
    non_core = [
      "dedicated=nonCritical:NoSchedule"
    ]
  }
}
