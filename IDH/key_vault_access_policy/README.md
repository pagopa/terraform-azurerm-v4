# Terraform Module: Key Vault Policy

This module allows you to centrally and parametrically manage Azure Key Vault access policies, assigning different permissions based on user/group type and environment.

## Features

- Default permissions for `admin`, `developer`, and `external` (by default, developer/external are readers)
- In the `dev` environment, developer and external receive elevated permissions (override)
- Easy override for any type+env combination
- No merge: either base or override permissions are used
- Tenant ID is passed as a variable

## How to Use Permission Overrides

Overrides allow you to assign a custom set of permissions for a specific combination of `permission_type` and `env`. If an override exists for the combination (e.g., `developer:dev`), the module will use those permissions instead of the base ones. If no override is found, the base permissions for the type are used.

### Example: Add or Change an Override

To add or modify an override, edit the `override_permissions` map in `main.tf` of the module:

```hcl
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
    # Add more overrides as needed, e.g.:
    # "developer:uat" = { ... }
  }
```

- The key must be in the format `<permission_type>:<env>` (e.g., `developer:dev`)
- The value is an object with the four permission lists
- If the combination is not present, the module falls back to the base permissions for that type

### How the Module Selects Permissions

- If an override exists for the given `permission_type` and `env`, it is used
- Otherwise, the base permissions for the `permission_type` are used
- No merging: only one set of permissions is applied

## Example Usage

```hcl
module "key_vault_policy_developer" {
  source         = "./modules/key_vault_policy"
  permission_type = "developer"
  env            = var.env
  key_vault_id   = module.key_vault[each.key].id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = data.azuread_group.adgroup_developers.object_id
}
```

## Notes

- You can easily extend the logic by adding new types or overrides in the `override_permissions` map.
- The module never merges base and override: it always chooses one or the other.
