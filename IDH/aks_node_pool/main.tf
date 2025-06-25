module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "aks_node_pool"
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
  vm_size                = module.idh_loader.idh_resource_configuration.vm_size
  os_disk_type           = module.idh_loader.idh_resource_configuration.os_disk_type
  os_disk_size_gb        = module.idh_loader.idh_resource_configuration.os_disk_size_gb
  ultra_ssd_enabled      = module.idh_loader.idh_resource_configuration.ultra_ssd_enabled
  enable_host_encryption = module.idh_loader.idh_resource_configuration.enable_host_encryption

  ###############################################################
  # Autoscaling
  ###############################################################
  autoscale_enabled = var.autoscale_enabled
  node_count_min    = var.node_count_min # must be >= node_min_allowed
  node_count_max    = var.node_count_max

  ###############################################################
  # Kubernetes runtime metadata
  ###############################################################
  node_labels = var.node_labels
  node_taints = var.node_taints

  ###############################################################
  # Upgrade surge settings
  ###############################################################
  upgrade_settings_max_surge = module.idh_loader.idh_resource_configuration.upgrade_settings_max_surge

  ###############################################################
  # Azure resource tagging
  ###############################################################
  node_tags = merge(
    lookup(module.idh_loader.idh_resource_configuration, "node_tags", {}),
    coalesce(var.node_tags, {})
  )

  tags = var.tags
}

# Validazione node_count_min rispetto a node_min_allowed
locals {
  node_min_allowed = try(module.idh_loader.idh_resource_configuration.node_min_allowed, null)
  node_count_min_valid = local.node_min_allowed == null || var.node_count_min >= coalesce(local.node_min_allowed, 0)
}

resource "null_resource" "validate_node_count_min" {
  count = local.node_count_min_valid ? 0 : 1
  provisioner "local-exec" {
    command = "echo 'Errore: node_count_min (${var.node_count_min}) deve essere >= node_min_allowed (${local.node_min_allowed})' && exit 1"
  }
}
