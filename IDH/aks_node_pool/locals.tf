locals {
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
