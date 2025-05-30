run "admin permissions should match base" {
  module {
    source = "../modules/key_vault_policy"
    permission_type = "admin"
    env = "prod"
    key_vault_id = "dummy-kv-id"
    tenant_id = "dummy-tenant-id"
    object_id = "dummy-object-id"
  }
  assert {
    condition = module.key_vault_policy_admin.key_permissions == [
      "Get", "List", "Update", "Create", "Import", "Delete", "Encrypt", "Decrypt", "Backup", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
    ]
    error_message = "Admin key permissions do not match base permissions."
  }
}

run "developer permissions should be reader in prod" {
  module {
    source = "../modules/key_vault_policy"
    permission_type = "developer"
    env = "prod"
    key_vault_id = "dummy-kv-id"
    tenant_id = "dummy-tenant-id"
    object_id = "dummy-object-id"
  }
  assert {
    condition = module.key_vault_policy_developer.key_permissions == ["Get", "List"]
    error_message = "Developer key permissions in prod should be reader."
  }
}

run "developer permissions should be elevated in dev" {
  module {
    source = "../modules/key_vault_policy"
    permission_type = "developer"
    env = "dev"
    key_vault_id = "dummy-kv-id"
    tenant_id = "dummy-tenant-id"
    object_id = "dummy-object-id"
  }
  assert {
    condition = module.key_vault_policy_developer.key_permissions == [
      "Get", "List", "Update", "Create", "Import", "Delete", "Encrypt", "Decrypt", "Rotate", "GetRotationPolicy"
    ]
    error_message = "Developer key permissions in dev should be elevated."
  }
}

run "reader permissions should always be Get and List" {
  module {
    source = "../modules/key_vault_policy"
    permission_type = "reader"
    env = "prod"
    key_vault_id = "dummy-kv-id"
    tenant_id = "dummy-tenant-id"
    object_id = "dummy-object-id"
  }
  assert {
    condition = module.key_vault_policy_reader.key_permissions == ["Get", "List"]
    error_message = "Reader key permissions should always be Get and List."
  }
}
