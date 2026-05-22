# keyvault_private_ca

Terraform module for creating a private Root CA on Azure Key Vault (Premium SKU, HSM-backed).

## How it works

1. Creates an Azure Key Vault (Premium SKU, HSM-backed)
2. Issues a self-signed Root CA (4096-bit RSA, 10 years, non-exportable)

## External organization onboarding (one-time)

```bash
# Export the Root CA public certificate
az keyvault certificate download \
  --vault-name <kv-name> \
  --name private-root-ca \
  --file pagopa-root-ca.pem \
  --encoding PEM

# Deliver pagopa-root-ca.pem to the external organization to be imported into their trust store
```

## Usage

```hcl
module "keyvault_private_ca" {
  source = "../../modules/keyvault_private_ca"

  resource_group_name = azurerm_resource_group.payments.name
  location            = var.location
  key_vault_prefix      = local.project
  tenant_id           = data.azurerm_client_config.current.tenant_id

  keyvault_administrator_principal_ids = [
    data.azuread_group.this.object_id,
  ]

  root_subject = "CN=PagoPA Private Root CA,O=PagoPA S.p.A.,C=IT"

  tags = local.tags
}
```

## Inputs / Variables

```hcl
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "key_vault_prefix" {
  type        = string
  description = "Prefix of the Key Vault"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD Tenant ID"
}

variable "keyvault_administrator_principal_ids" {
  type        = list(string)
  description = "List of principal IDs (managed identity, service principal) with the Key Vault Administrator role"
}

variable "root_subject" {
  type        = string
  description = "Subject of the Root CA (e.g., 'CN=PagoPA Private Root CA,O=PagoPA S.p.A.,C=IT')"
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
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