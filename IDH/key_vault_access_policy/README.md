# Terraform Module: Key Vault Policy

This module allows you to centrally and parametrically manage Azure Key Vault access policies, assigning different permissions based on user/group type and environment.

## Usage

To use this module, include it in your Terraform configuration as follows:

```hcl
module "key_vault_access_policy" {
  source         = "<path-to-this-module>"
  prefix         = "cstar"
  tags           = { environment = "dev" }
  permission_tier = "admin" # or developer, external
  env            = "dev" # or prod, uat, etc.
  key_vault_id   = "<your-key-vault-id>"
  tenant_id      = "<your-tenant-id>"
  object_id      = "<object-id-to-assign-policy>"
}
```

### Input Variables

- `prefix` (string, required): Prefix used to identify the platform for which the resource will be created.
- `idh_resource` (string, required): The name of the IDH resource key to be created.
- `tags` (map(string), optional): Tags to apply to resources. Default is `{}`.
- `permission_type` (string, required): The type of permission: `admin`, `developer`, or `external`.
- `env` (string, required): The environment: `dev`, `prod`, `uat`, etc.
- `key_vault_id` (string, required): The ID of the Key Vault to which the policy will be applied.
- `tenant_id` (string, required): Azure Tenant ID.
- `object_id` (string, required): Object ID of the group or identity to assign the policy to.
