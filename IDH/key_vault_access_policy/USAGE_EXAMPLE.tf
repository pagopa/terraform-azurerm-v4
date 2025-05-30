# Esempio di utilizzo del modulo key_vault_policy
module "key_vault_policy_admin" {
  source         = "./modules/key_vault_policy"
  permission_type = "admin"
  env            = var.env
  key_vault_id   = module.key_vault[each.key].id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = data.azuread_group.adgroup_admin.object_id
}

module "key_vault_policy_developer" {
  source         = "./modules/key_vault_policy"
  permission_type = "developer"
  env            = var.env
  key_vault_id   = module.key_vault[each.key].id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = data.azuread_group.adgroup_developers.object_id
}

module "key_vault_policy_external" {
  source         = "./modules/key_vault_policy"
  permission_type = "external"
  env            = var.env
  key_vault_id   = module.key_vault[each.key].id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = data.azuread_group.adgroup_externals.object_id
}
