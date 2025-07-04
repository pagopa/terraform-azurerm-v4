module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = basename(path.module) ## folder name
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions         = module.idh_loader.idh_resource_configuration.key_permissions
  secret_permissions      = module.idh_loader.idh_resource_configuration.secret_permissions
  storage_permissions     = module.idh_loader.idh_resource_configuration.storage_permissions
  certificate_permissions = module.idh_loader.idh_resource_configuration.certificate_permissions
}
