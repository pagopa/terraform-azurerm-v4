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
  vnet_subnet_id        = var.embedded_subnet.enabled ? try(module.aks_overlay_snet[0].subnet_id, null) : var.vnet_subnet_id

  ###############################################################
  # Compute & Storage settings (safe‑lookup + try() wrapper)
  ###############################################################
  vm_size                = module.idh_loader.idh_resource_configuration.vm_size
  os_disk_type           = var.os_disk_type != null ? var.os_disk_type : module.idh_loader.idh_resource_configuration.os_disk_type
  os_disk_size_gb        = var.os_disk_size_gb != null ? var.os_disk_size_gb : module.idh_loader.idh_resource_configuration.os_disk_size_gb
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

  depends_on = [module.aks_overlay_snet]
}

# IDH/subnet
module "aks_overlay_snet" {
  source = "../subnet"
  count  = var.embedded_subnet.enabled ? 1 : 0

  name                 = "${var.embedded_subnet.subnet_name}-aks-overlay-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  env               = var.env
  idh_resource_tier = "aks_overlay"
  product_name      = var.product_name

  nsg_flow_log_configuration   = var.nsg_flow_log_configuration
  embedded_nsg_configuration   = var.embedded_nsg_configuration
  create_self_inbound_nsg_rule = var.create_self_inbound_nsg_rule

  tags = var.tags
}

resource "azurerm_subnet_nat_gateway_association" "aks_overlay_snet_nat_association" {
  count = var.embedded_subnet.enabled ? 1 : 0

  subnet_id      = module.aks_overlay_snet[0].subnet_id
  nat_gateway_id = var.embedded_subnet.natgw_id
}