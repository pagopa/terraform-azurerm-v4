module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "key_vault"
}

# -------------------------------------------------------------------
# Key Vault
# -------------------------------------------------------------------
module "key_vault" {
  source = "../../key_vault"

  name                = var.name
  resource_group_name = var.resource_group_name

  location                       = var.location
  sec_log_analytics_workspace_id = var.sec_log_analytics_workspace_id
  sec_storage_id                 = var.sec_storage_id
  tenant_id                      = var.tenant_id
  terraform_cloud_object_id      = var.terraform_cloud_object_id

  # Networking
  private_endpoint_enabled             = var.private_endpoint_enabled
  private_endpoint_resource_group_name = var.private_endpoint_resource_group_name
  private_endpoint_subnet_id           = var.private_endpoint_subnet_id
  private_dns_zones_ids                = var.private_dns_zones_ids

  enable_rbac_authorization     = module.idh_loader.idh_resource_configuration.enable_rbac_authorization
  lock_enable                   = module.idh_loader.idh_resource_configuration.lock_enabled
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  soft_delete_retention_days    = module.idh_loader.idh_resource_configuration.soft_delete_retention_days
  sku_name                      = module.idh_loader.idh_resource_configuration.sku_name

  tags = var.tags
}
