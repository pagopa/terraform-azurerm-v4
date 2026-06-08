# keyvault_client_certificates

Terraform module for issuing and managing mTLS client certificates signed by an internal private CA stored in Azure Key Vault.

## How it works

1. Reads the Root CA certificate from a source Key Vault
2. Uses the Root CA private key (HSM-backed) from the source vault to sign client certificates
3. Stores each client certificate in its own destination Key Vault (specified per certificate)

The key insight is that the Root CA remains in its own secure vault, while client certificates can be distributed to different destination vaults as needed.

## Usage

```hcl
module "keyvault_client_certificates" {
  source = "../../modules/keyvault_client_certificates"

  # Source vault: where Root CA is stored
  root_key_vault_name = "my-ca-kv"
  root_key_vault_id   = azurerm_key_vault.ca.id

  # Each certificate can go to a different destination vault
  certificates = {
    "client-service-a" = {
      key_vault_name     = "vault-for-service-a"  # Destination vault
      subject            = "CN=service-a,O=PagoPA S.p.A.,C=IT"
      validity_in_months = 3
      san_dns_names      = ["service-a.internal"]
    }
    "client-service-b" = {
      key_vault_name     = "vault-for-service-b"  # Different destination vault
      subject            = "CN=service-b,O=PagoPA S.p.A.,C=IT"
      validity_in_months = 6
    }
  }

  tags = var.tags
}
```

## Inputs / Variables

```hcl
variable "root_key_vault_name" {
  type        = string
  description = "Name of the Key Vault containing the Root CA (source)"
}

variable "root_key_vault_id" {
  type        = string
  description = "ID of the Key Vault containing the Root CA (source)"
}

variable "certificates" {
  description = "Map of client certificates to be issued"
  type = map(object({
    key_vault_name     = string  # Destination Key Vault for this certificate
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
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.12 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [terraform_data.client_cert_sign](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.client_cert_sign_cleanup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.client_cert_stable](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.client_cert_stable_cleanup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_rotating.cert_rotation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [time_rotating.cert_stable](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [azurerm_key_vault_certificate.root_ca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of client certificates to be issued | <pre>map(object({<br/>    key_vault_name                      = string<br/>    subject                             = string<br/>    validity_in_months                  = number<br/>    san_dns_names                       = optional(list(string), [])<br/>    renewal_days_before_expiry          = optional(number, 30)<br/>    stable_promotion_days_before_expiry = optional(number, 7)<br/><br/>  }))</pre> | `{}` | no |
| <a name="input_root_key_vault_id"></a> [root\_key\_vault\_id](#input\_root\_key\_vault\_id) | ID of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_root_key_vault_name"></a> [root\_key\_vault\_name](#input\_root\_key\_vault\_name) | Name of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->