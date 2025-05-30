locals {
  # Permessi base per ogni tipologia
  base_permissions = {
    admin = {
      key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Encrypt", "Decrypt", "Backup", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Backup", "Purge", "Recover", "Restore"]
      storage_permissions     = []
      certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Restore", "Purge", "Recover", "Backup", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
    }
    developer = {
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List"]
      storage_permissions     = []
      certificate_permissions = ["Get", "List"]
    }
    external = {
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List"]
      storage_permissions     = []
      certificate_permissions = ["Get", "List"]
    }
    reader = {
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List"]
      storage_permissions     = []
      certificate_permissions = ["Get", "List"]
    }
  }

  # Override per combinazioni specifiche tipologia+env (dev: permessi elevati)
  override_permissions = {
    "developer:dev" = {
      key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Encrypt", "Decrypt", "Rotate", "GetRotationPolicy"]
      secret_permissions      = ["Get", "List", "Set", "Delete"]
      storage_permissions     = []
      certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Restore", "Purge", "Recover"]
    }
    "external:dev" = {
      key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Encrypt", "Decrypt", "Rotate", "GetRotationPolicy"]
      secret_permissions      = ["Get", "List", "Set", "Delete"]
      storage_permissions     = []
      certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Restore", "Purge", "Recover"]
    }
    # Aggiungi altri override se necessario
  }

  # Se esiste override per tipologia+env, usa quello, altrimenti usa il base
  selected_permissions = (
    contains(keys(local.override_permissions), "${var.permission_type}:${var.env}")
    ? local.override_permissions["${var.permission_type}:${var.env}"]
    : local.base_permissions[var.permission_type]
  )
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions         = local.selected_permissions.key_permissions
  secret_permissions      = local.selected_permissions.secret_permissions
  storage_permissions     = local.selected_permissions.storage_permissions
  certificate_permissions = local.selected_permissions.certificate_permissions
}
