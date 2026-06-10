# keyvault_private_ca

Terraform module that provisions a private Root CA entirely inside Azure Key Vault (Premium SKU, HSM-backed).

## Architecture

The module creates a dedicated Key Vault (`<prefix>-ca-kv`) used exclusively to hold the Root CA. Separation from other Key Vaults is intentional: it limits blast radius and allows tighter RBAC policies on the CA material.

The Root CA certificate is self-signed, 4096-bit RSA, valid for 10 years. The private key is generated directly inside the HSM (`exportable: false`) and **never leaves the vault** — signing operations are always performed via the Key Vault Cryptography API.

## Resources created

| Resource | Description |
|---|---|
| `<prefix>-ca-kv` | Dedicated Key Vault (Premium SKU, soft delete 90 days) |
| `private-root-ca` | Root CA certificate inside the vault |
| `azurerm_role_assignment` | Key Vault Administrator role for each principal in `keyvault_administrator_principal_ids` |

## Relationship with keyvault_client_certificates

This module is a prerequisite for `keyvault_client_certificates`. Its outputs (`key_vault_id`, `key_vault_name`) are passed as inputs to the client certificates module to locate the CA.

```hcl
module "private_ca" {
  source = "../keyvault_private_ca"
  # ...
}

module "client_certificates" {
  source = "../keyvault_client_certificates"

  root_key_vault_id   = module.private_ca.key_vault_id
  root_key_vault_name = module.private_ca.key_vault_name
  # ...
}
```

## Recreating the CA

`terraform_data.create_private_ca` uses `triggers_replace` on `root_subject` and `validity_months`. Changing either will destroy and recreate the CA, generating a new key pair with a new certificate.

Already-issued client certificates remain **cryptographically valid** — their signature was produced by the old CA private key and can still be verified against the old CA public certificate held in the server's trust store. mTLS continues to work for existing certificates until they expire.

What changes after recreation:
- New client certificates can only be issued by the new CA
- External systems must add the new CA public certificate to their trust store before trusting new client certificates
- The old CA public certificate can be removed from trust stores only after all client certificates signed by it have been rotated and replaced

## External organization onboarding

To enable an external system to verify client certificates issued by this CA, distribute the Root CA public certificate:

```bash
az keyvault certificate download \
  --vault-name <prefix>-ca-kv \
  --name private-root-ca \
  --file pagopa-root-ca.pem \
  --encoding PEM
```

The receiving system imports `pagopa-root-ca.pem` into its trust store. No private key material is involved.

## Usage

```hcl
module "keyvault_private_ca" {
  source = "../../modules/keyvault_private_ca"

  resource_group_name = azurerm_resource_group.payments.name
  location            = var.location
  key_vault_prefix    = local.project
  tenant_id           = data.azurerm_client_config.current.tenant_id

  keyvault_administrator_principal_ids = [
    data.azuread_group.this.object_id,
  ]

  root_subject = "CN=PagoPA Private Root CA,O=PagoPA S.p.A.,C=IT"

  tags = local.tags
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_keyvault"></a> [keyvault](#module\_keyvault) | ../key_vault | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.admin_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [terraform_data.create_private_ca](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key_vault_prefix"></a> [key\_vault\_prefix](#input\_key\_vault\_prefix) | Name of the prefix Key Vault | `string` | n/a | yes |
| <a name="input_keyvault_administrator_principal_ids"></a> [keyvault\_administrator\_principal\_ids](#input\_keyvault\_administrator\_principal\_ids) | List of principal IDs (managed identity, service principal) with the Key Vault Administrator role | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_root_subject"></a> [root\_subject](#input\_root\_subject) | Subject of the Root CA (e.g., 'CN=PagoPA Private Root CA,O=PagoPA S.p.A.,C=IT') | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map(string)` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Azure AD Tenant ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id) | n/a |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | n/a |
<!-- END_TF_DOCS -->
