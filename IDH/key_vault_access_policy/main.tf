module "idh_loader" {
  source       = "../00_idh_loader"
  prefix       = var.prefix
  env          = var.env
  idh_resource = var.permission_tier
  idh_category = basename(path.module) ## folder name
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions         = module.idh_loader.idh_config.key_permissions
  secret_permissions      = module.idh_loader.idh_config.secret_permissions
  storage_permissions     = module.idh_loader.idh_config.storage_permissions
  certificate_permissions = module.idh_loader.idh_config.certificate_permissions
}
