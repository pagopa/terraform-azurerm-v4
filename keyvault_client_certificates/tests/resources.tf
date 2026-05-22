data "azurerm_client_config" "current" {}

data "azuread_group" "this" {
  display_name = local.admin_azuread_group
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-cert-auth2-rg"
  location = var.location

  tags = var.tags
}

module "private_ca" {
  source = "../../keyvault_private_ca"

  key_vault_prefix    = var.prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tenant_id                            = data.azurerm_client_config.current.tenant_id
  keyvault_administrator_principal_ids = [data.azuread_group.this.object_id]

  root_subject = "CN=PagoPA Root CA - ${var.prefix} DEV, OU=DevOps, O=PagoPA S.p.A., C=IT"

  tags = azurerm_resource_group.rg.tags
}

module "client_certificate" {
  source = "../"

  key_vault_name = module.private_ca.key_vault_name
  key_vault_id   = module.private_ca.key_vault_id

  certificates = {
    "test-mtls" = {
      subject            = "CN=devopla,OU=DevOps,O=DevOpsLabs,C=IT"
      validity_in_months = 3
    }
    "test-mtls-v2" = {
      subject            = "CN=devopla-v2,OU=DevOps,O=DevOpsLabs,C=IT"
      validity_in_months = 2
    }
  }

  tags = azurerm_resource_group.rg.tags

  depends_on = [module.private_ca]
}
