module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "aks_node_pool"
}

locals {
  # Safe accessor: if the module output is undefined we fall back to an empty object
  idh_resource_configuration = try(module.idh_loader.idh_resource_configuration, {})
}

module "aks_node_pool" {
  source = "../../kubernetes_cluster_node_pool"

  # Core identifiers
  name                  = var.name
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vnet_subnet_id        = var.vnet_subnet_id

  # Compute & storage
  vm_size               = coalesce(var.vm_size, lookup(local.idh_resource_configuration, "vm_size", null))
  os_disk_type          = coalesce(var.os_disk_type, lookup(local.idh_resource_configuration, "os_disk_type", null))
  os_disk_size_gb       = coalesce(var.os_disk_size_gb, lookup(local.idh_resource_configuration, "os_disk_size_gb", null))
  zones                 = coalesce(var.zones, lookup(local.idh_resource_configuration, "zones", null))
  ultra_ssd_enabled     = coalesce(var.ultra_ssd_enabled, lookup(local.idh_resource_configuration, "ultra_ssd_enabled", null))
  enable_host_encryption = coalesce(var.enable_host_encryption, lookup(local.idh_resource_configuration, "enable_host_encryption", null))

  # Autoscaling
  node_count_min        = coalesce(var.node_count_min, lookup(local.idh_resource_configuration, "node_count_min", null))
  node_count_max        = coalesce(var.node_count_max, lookup(local.idh_resource_configuration, "node_count_max", null))

  # Networking
  max_pods              = coalesce(var.max_pods, lookup(local.idh_resource_configuration, "max_pods", null))

  # Kubernetes runtime metadata
  node_labels = merge(
    lookup(local.idh_resource_configuration, "node_labels", {}),
    var.node_labels
  )

  node_taints = coalesce(var.node_taints, lookup(local.idh_resource_configuration, "node_taints", null))

  # Upgrade surge settings
  upgrade_settings_max_surge = coalesce(var.upgrade_settings_max_surge, lookup(local.idh_resource_configuration, "upgrade_settings_max_surge", null))

  # Azure resource tagging
  node_tags = merge(
    lookup(local.idh_resource_configuration, "node_tags", {}),
    var.node_tags
  )

  tags = var.tags
}

