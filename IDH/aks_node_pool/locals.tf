locals {
  node_pool_foo_name  = var.double_node_pool.enabled ? "${var.name}foo" : var.name
  node_pool_bar_name  = "${var.name}bar"

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
