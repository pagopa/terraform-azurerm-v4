resource "random_string" "rotation" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  kubernetes_cluster_id = var.kubernetes_cluster_id

  name = var.name

  vm_size               = var.vm_size
  os_disk_type          = var.os_disk_type
  os_disk_size_gb       = var.os_disk_size_gb
  zones                 = var.zones
  ultra_ssd_enabled     = var.ultra_ssd_enabled
  host_encryption_enabled = var.enable_host_encryption
  os_type               = "Linux"

  auto_scaling_enabled  = true
  node_count            = var.node_count_min
  min_count             = var.node_count_min
  max_count             = var.node_count_max

  max_pods                    = var.max_pods

  node_labels                 = var.node_labels
  node_taints                 = var.node_taints
  temporary_name_for_rotation = "${substr(var.name, 0, 8)}${random_string.rotation.result}"

  vnet_subnet_id         = var.vnet_subnet_id
  node_public_ip_enabled = false

  upgrade_settings {
    max_surge = var.upgrade_settings_max_surge
    drain_timeout_in_minutes = 30
  }

  tags = merge(var.tags, var.node_tags)

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
