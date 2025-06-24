module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "aks_node_pool"
}

module "aks_node_pool" {
  source = "../../kubernetes_cluster_node_pool"

  kubernetes_cluster_id = var.kubernetes_cluster_id
  name                  = var.name

  vm_size               = coalesce(var.vm_size, module.idh_loader.idh_resource_configuration.vm_size)
  os_disk_type          = coalesce(var.os_disk_type, module.idh_loader.idh_resource_configuration.os_disk_type)
  os_disk_size_gb       = coalesce(var.os_disk_size_gb, module.idh_loader.idh_resource_configuration.os_disk_size_gb)
  zones                 = coalesce(var.zones, module.idh_loader.idh_resource_configuration.zones)
  ultra_ssd_enabled     = coalesce(var.ultra_ssd_enabled, module.idh_loader.idh_resource_configuration.ultra_ssd_enabled)
  enable_host_encryption = coalesce(var.enable_host_encryption, module.idh_loader.idh_resource_configuration.enable_host_encryption)

  node_count_min        = coalesce(var.node_count_min, module.idh_loader.idh_resource_configuration.node_count_min)
  node_count_max        = coalesce(var.node_count_max, module.idh_loader.idh_resource_configuration.node_count_max)

  max_pods              = coalesce(var.max_pods, module.idh_loader.idh_resource_configuration.max_pods)

  node_labels           = merge(coalesce(module.idh_loader.idh_resource_configuration.node_labels, {}), var.node_labels)
  node_taints           = coalesce(var.node_taints, module.idh_loader.idh_resource_configuration.node_taints)

  vnet_subnet_id        = var.vnet_subnet_id

  upgrade_settings_max_surge = coalesce(var.upgrade_settings_max_surge, module.idh_loader.idh_resource_configuration.upgrade_settings_max_surge)

  node_tags             = merge(coalesce(module.idh_loader.idh_resource_configuration.node_tags, {}), var.node_tags)
  tags                  = var.tags
}
