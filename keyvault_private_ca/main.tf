locals {
  private_root_ca_name = "private-root-ca"
  validity_months      = 120
}

# -----------------------------------------------
# Key Vault
# -----------------------------------------------
module "keyvault" {
  source = "../key_vault"

  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name                   = "premium" # Premium per HSM-backed keys
  rbac_authorization_enabled = true
  soft_delete_retention_days = 90

  tags = var.tags
}

# -----------------------------------------------
# RBAC: Key Vault Administrator
# -----------------------------------------------
resource "azurerm_role_assignment" "admin_kv" {
  for_each = toset(var.keyvault_administrator_principal_ids)

  scope                = module.keyvault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "terraform_data" "create_private_ca" {
  triggers_replace = {
    vault_name      = var.key_vault_name
    cert_name       = local.private_root_ca_name
    root_subject    = var.root_subject
    validity_months = local.validity_months
    tags_json       = jsonencode(var.tags != null ? var.tags : {})
  }

  provisioner "local-exec" {
    command = <<EOT
      az rest --method post \
        --url "https://${self.triggers_replace.vault_name}.vault.azure.net/certificates/${self.triggers_replace.cert_name}/create?api-version=7.4" \
        --resource "https://vault.azure.net" \
        --headers "Content-Type=application/json" \
        --body '{
          "policy": {
            "issuer": {
              "name": "Self"
            },
            "key_props": {
              "exportable": false,
              "key_type": "RSA",
              "key_size": 4096
            },
            "x509_props": {
              "subject": "${self.triggers_replace.root_subject}",
              "validity_months": ${self.triggers_replace.validity_months},
              "key_usage": [
                "cRLSign",
                "keyCertSign",
                "digitalSignature"
              ],
              "basic_constraints": {
                "ca": true,
                "path_len_constraint": 0
              }
            }
          },
          "tags": ${self.triggers_replace.tags_json}
        }'
    EOT
  }

  provisioner "local-exec" {
    when = destroy

    command = <<EOT
      az rest --method delete \
        --url "https://${self.triggers_replace.vault_name}.vault.azure.net/certificates/${self.triggers_replace.cert_name}?api-version=7.4" \
        --resource "https://vault.azure.net"
    EOT
  }

  depends_on = [
    module.keyvault,
    azurerm_role_assignment.admin_kv
  ]
}