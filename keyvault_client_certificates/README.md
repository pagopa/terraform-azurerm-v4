# keyvault_client_certificates

Terraform module for issuing and managing mTLS client certificates signed by an internal private CA stored in Azure Key Vault.

## How it works

1. Reads the Root CA certificate from a dedicated CA Key Vault
2. Generates a new key pair and CSR directly inside the destination Key Vault
3. Signs the certificate via the CA Key Vault Cryptography API — the CA private key never leaves the vault
4. Stores the signed certificate in the destination Key Vault following the **current/stable pattern**

### Current / stable pattern

Each certificate is represented by four secrets in the destination Key Vault:

| Secret | Description |
|---|---|
| `<name>-pfx` | Current certificate — updated on every renewal (PKCS#12) |
| `<name>-stable-pfx` | Stable certificate — what clients actually mount (PKCS#12) |
| `<name>-stable-key` | Private key of the stable certificate (PEM) |
| `<name>-stable-cert` | Public certificate of the stable certificate (PEM) |

Clients read only the `-stable-*` secrets. The current certificate (`-pfx`) can be renewed without impacting running services; clients pick up the new certificate only when the stable is explicitly promoted.

### Automatic rotation

Two `time_rotating` resources per certificate drive the lifecycle without any manual intervention or git changes:

| Resource | Fires after | Action |
|---|---|---|
| `time_rotating.cert_rotation` | `validity_months * 30 - renewal_days_before_expiry` days | Renews `-pfx` |
| `time_rotating.cert_stable` | `validity_months * 30 - stable_promotion_days_before_expiry` days | Promotes `-pfx` → `-stable-*` |

Because rotation always fires before promotion, the two events never overlap.

### Cleanup on certificate removal

Removing a certificate from the `certificates` map and applying will soft-delete all four secrets from the destination Key Vault. The destroy provisioners use `input` (not `triggers_replace`) so they only run on actual removal — never on rotation.

## Usage

```hcl
module "keyvault_client_certificates" {
  source = "../../modules/keyvault_client_certificates"

  root_key_vault_name = module.private_ca.key_vault_name
  root_key_vault_id   = module.private_ca.key_vault_id

  certificates = {
    "my-service" = {
      key_vault_name                      = module.kv_app.name
      subject                             = "CN=my-service,O=PagoPA S.p.A.,C=IT"
      validity_in_months                  = 3
      renewal_days_before_expiry          = 30
      stable_promotion_days_before_expiry = 7
    }
    "pagopa-forwarder" = {
      key_vault_name                      = module.kv_forwarder.name
      subject                             = "CN=pagopa-forwarder,O=PagoPA S.p.A.,C=IT"
      validity_in_months                  = 12
      renewal_days_before_expiry          = 50
      stable_promotion_days_before_expiry = 20
      san_dns_names                       = ["forwarder.internal.pagopa.it"]
    }
  }

  tags = var.tags
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
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of client certificates to be issued | <pre>map(object({<br/>    key_vault_name                      = string<br/>    subject                             = string<br/>    validity_in_months                  = number<br/>    san_dns_names                       = optional(list(string), [])<br/>    renewal_days_before_expiry          = optional(number, 60)<br/>    stable_promotion_days_before_expiry = optional(number, 20)<br/>  }))</pre> | `{}` | no |
| <a name="input_root_key_vault_id"></a> [root\_key\_vault\_id](#input\_root\_key\_vault\_id) | ID of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_root_key_vault_name"></a> [root\_key\_vault\_name](#input\_root\_key\_vault\_name) | Name of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
