# keyvault_client_certificates

Terraform module for issuing and managing mTLS client certificates signed by an internal private CA stored in Azure Key Vault.

## How it works

1. Loads an existing Root CA from Azure Key Vault
2. Issues client certificates signed by the internal CA with configurable validity

## Usage

```hcl
module "keyvault_client_certificates" {
  source = "../../modules/keyvault_client_certificates"

  key_vault_name = azurerm_key_vault.example.name
  key_vault_id   = azurerm_key_vault.example.id

  certificates = {
    "pagopa-ente-alfa-client" = {
      subject            = "CN=pagopa-ente-alfa-client,O=PagoPA S.p.A.,C=IT"
      validity_in_months = 3
      san_dns_names      = []
    }
  }
  tags = var.tags
}
```

## Inputs / Variables

```hcl
variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "key_vault_id" {
  type        = string
  description = "ID of the Key Vault"
}

variable "certificates" {
  description = "Map of client certificates to be issued"
  type = map(object({
    subject            = string
    validity_in_months = number
    san_dns_names      = optional(list(string), [])
  }))
  default = {}
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

No modules.

## Resources

| Name | Type |
|------|------|
| [terraform_data.client_cert_sign](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_key_vault_certificate.root_ca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of client certificates to be issued | <pre>map(object({<br/>    key_vault_name     = string<br/>    subject            = string<br/>    validity_in_months = number<br/>    san_dns_names      = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Name of the Key Vault (destination, where client certificates are stored) | `string` | n/a | yes |
| <a name="input_root_key_vault_id"></a> [root\_key\_vault\_id](#input\_root\_key\_vault\_id) | ID of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_root_key_vault_name"></a> [root\_key\_vault\_name](#input\_root\_key\_vault\_name) | Name of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->