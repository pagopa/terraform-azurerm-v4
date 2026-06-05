data "azurerm_client_config" "current" {}

data "azuread_group" "this" {
  display_name = local.admin_azuread_group
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-cert-auth-v2-rg"
  location = var.location

  tags = var.tags
}

module "kv_client" {
  source = "../../key_vault"

  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = "${var.prefix}-d-v2-cert-kv"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
}

resource "azurerm_key_vault_access_policy" "access_policy" {
  key_vault_id = module.kv_client.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azuread_group.this.object_id

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Import",
    "Update",
    "ManageContacts",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
    "ManageIssuers"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

module "private_ca" {
  source = "../../keyvault_private_ca"

  key_vault_prefix    = "${var.prefix}-d-v2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tenant_id                            = data.azurerm_client_config.current.tenant_id
  keyvault_administrator_principal_ids = [data.azuread_group.this.object_id]

  root_subject = "CN=PagoPA Root CA - ${var.prefix} DEV, OU=DevOps, O=PagoPA S.p.A., C=IT"

  tags = azurerm_resource_group.rg.tags
}

module "client_certificate" {
  source = "../"

  root_key_vault_id   = module.private_ca.key_vault_id
  root_key_vault_name = module.private_ca.key_vault_name

  # X days before cert-stable expiry: reissue the current certificate
  renewal_days_before_expiry = var.renewal_days_before_expiry

  # Y days before cert-stable expiry: promote current to stable
  stable_promotion_days_before_expiry = var.stable_promotion_days_before_expiry

  # For testing only: overrides rotation_days with rotation_minutes
  rotation_minutes_override        = var.rotation_minutes_override
  stable_rotation_minutes_override = var.stable_rotation_minutes_override

  certificates = {
    "test-mtls-forwarder" = {
      key_vault_name     = module.kv_client.name
      subject            = "CN=devopla-v2,OU=DevOps,O=DevOpsLabs,C=IT"
      validity_in_months = 3
    }
    "test-mtls-forwarder-2" = {
      key_vault_name     = module.kv_client.name
      subject            = "CN=devopla-v3,OU=DevOps,O=DevOpsLabs,C=IT"
      validity_in_months = 2
      san_dns_names      = ["*.forwarder.dev.platform.pagopa.it"]
    }
  }

  tags = azurerm_resource_group.rg.tags

  depends_on = [
    module.private_ca,
    azurerm_key_vault_access_policy.access_policy
  ]
}
