module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "aks_node_pool"
}

locals {
  # Retrieve IDH loader configuration if present; otherwise use an empty object
  idh_cfg = try(module.idh_loader.idh_resource_configuration, {})
}

module "aks_node_pool" {
  source = "../../kubernetes_cluster_node_pool"

  # Core identifiers
  name                  = var.name
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vnet_subnet_id        = var.vnet_subnet_id

  ###############################################################
  # Compute & Storage settings (safe‑lookup + try() wrapper)
  ###############################################################
  vm_size                = try(coalesce(var.vm_size, lookup(local.idh_cfg, "vm_size", null)), null)
  os_disk_type           = try(coalesce(var.os_disk_type, lookup(local.idh_cfg, "os_disk_type", null)), null)
  os_disk_size_gb        = try(coalesce(var.os_disk_size_gb, lookup(local.idh_cfg, "os_disk_size_gb", null)), null)
  zones                  = try(coalesce(var.zones, lookup(local.idh_cfg, "zones", null)), null)
  ultra_ssd_enabled      = try(coalesce(var.ultra_ssd_enabled, lookup(local.idh_cfg, "ultra_ssd_enabled", null)), null)
  enable_host_encryption = try(coalesce(var.enable_host_encryption, lookup(local.idh_cfg, "enable_host_encryption", null)), null)

  ###############################################################
  # Autoscaling
  ###############################################################
  autoscale_enabled = var.autoscale_enabled
  node_count_min    = var.node_count_min
  node_count_max    = var.node_count_max

  ###############################################################
  # Networking
  ###############################################################
  max_pods = try(coalesce(var.max_pods, lookup(local.idh_cfg, "max_pods", null)), null)

  ###############################################################
  # Kubernetes runtime metadata
  ###############################################################
  node_labels = merge(
    lookup(local.idh_cfg, "node_labels", {}),
    coalesce(var.node_labels, {})
  )

  node_taints = try(coalesce(var.node_taints, lookup(local.idh_cfg, "node_taints", null)), null)

  ###############################################################
  # Upgrade surge settings
  ###############################################################
  upgrade_settings_max_surge = try(coalesce(var.upgrade_settings_max_surge, lookup(local.idh_cfg, "upgrade_settings_max_surge", null)), null)

  ###############################################################
  # Azure resource tagging
  ###############################################################
  node_tags = merge(
    lookup(local.idh_cfg, "node_tags", {}),
    coalesce(var.node_tags, {})
  )

  tags = var.tags
}


