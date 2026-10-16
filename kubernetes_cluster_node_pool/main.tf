resource "random_string" "rotation" {
  length  = 4
  upper   = false
  special = false
}


# Read the cluster (not the pools) so that pools not yet created don't fail the lookup:
# the current node_count is available only for pools that already exist.
data "azurerm_kubernetes_cluster" "this" {
  name                = local.cluster_name
  resource_group_name = local.cluster_rg_name
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  kubernetes_cluster_id = var.kubernetes_cluster_id

  orchestrator_version = var.orchestrator_version

  name = var.name

  vm_size                 = var.vm_size
  os_disk_type            = var.os_disk_type
  os_disk_size_gb         = var.os_disk_size_gb
  zones                   = var.zones
  ultra_ssd_enabled       = var.ultra_ssd_enabled
  host_encryption_enabled = var.enable_host_encryption
  os_type                 = "Linux"

  auto_scaling_enabled = var.autoscale_enabled
  node_count           = var.override_node_count.enabled ? var.override_node_count.count : lookup(local.current_node_counts, var.name, var.node_count_min)
  min_count            = var.node_count_min
  max_count            = var.node_count_max

  max_pods = var.max_pods

  node_labels                 = var.node_labels
  node_taints                 = var.node_taints
  temporary_name_for_rotation = "${substr(var.name, 0, 8)}${random_string.rotation.result}"

  vnet_subnet_id         = var.vnet_subnet_id
  node_public_ip_enabled = false

  upgrade_settings {
    max_surge                = var.upgrade_settings_max_surge
    drain_timeout_in_minutes = 30
  }

  tags = merge(var.tags, var.node_tags)

}
