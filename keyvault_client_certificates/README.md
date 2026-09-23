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

### Automatic renewal, manual promotion

Renewal of the current certificate is automatic: `time_rotating.cert_rotation` fires after `validity_months * 30 - renewal_days_before_expiry` days and renews `-pfx`.

Promotion `-pfx` → `-stable-*` is manual and driven by the per-certificate `stable_promotion_id` attribute: every time it is set to a new value, the next apply promotes that certificate (and only that one). Any string of letters, digits, `.`, `_` or `-` is accepted; the promotion date (e.g. `"2026-09-23"`) is a convenient choice because it also records when the stable was last promoted.

| `stable_promotion_id` | Effect on apply |
|---|---|
| unchanged | Nothing is promoted, even if `-pfx` was renewed in the meantime |
| changed to a new value | `-pfx` is promoted to `-stable-*` |
| `null` | Nothing is promoted |

If a promotion fails, the resource stays tainted and the next apply retries it with the same id.

> [!IMPORTANT]
> The first deploy of a certificate must always set `stable_promotion_id`: with `null`, the certificate is issued but no `-stable-*` secret is created, and clients reading them fail.

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
      key_vault_name             = module.kv_app.name
      subject                    = "CN=my-service,O=PagoPA S.p.A.,C=IT"
      validity_in_months         = 3
      renewal_days_before_expiry = 30
      # Change it to promote -pfx to -stable-*; must be set on the first deploy
      stable_promotion_id        = "2026-09-23"
    }
    "pagopa-forwarder" = {
      key_vault_name             = module.kv_forwarder.name
      subject                    = "CN=pagopa-forwarder,O=PagoPA S.p.A.,C=IT"
      validity_in_months         = 12
      renewal_days_before_expiry = 50
      san_dns_names              = ["forwarder.internal.pagopa.it"]
      stable_promotion_id        = "2026-09-23"
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
| [azurerm_key_vault_certificate.leaf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |
| [azurerm_key_vault_certificate.root_ca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of client certificates to be issued. Set key\_vault\_id to have the module expose the leaf + root CA PEM chain in the certificate\_chain\_pem output. Set stable\_promotion\_id to a new value (e.g. the promotion date) to promote that certificate (<name>-pfx) to its stable secrets (<name>-stable-*); null never promotes. The first deploy of a certificate must set it, otherwise no -stable-* secret is created. | <pre>map(object({<br/>    key_vault_name             = string<br/>    key_vault_id               = optional(string, null)<br/>    subject                    = string<br/>    validity_in_months         = number<br/>    san_dns_names              = optional(list(string), [])<br/>    renewal_days_before_expiry = optional(number, 60)<br/>    stable_promotion_id        = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_root_key_vault_id"></a> [root\_key\_vault\_id](#input\_root\_key\_vault\_id) | ID of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_root_key_vault_name"></a> [root\_key\_vault\_name](#input\_root\_key\_vault\_name) | Name of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_chain_pem"></a> [certificate\_chain\_pem](#output\_certificate\_chain\_pem) | Full PEM chain (current leaf certificate followed by the root CA) per certificate name. Only populated for certificates declaring key\_vault\_id. |
| <a name="output_root_ca_pem"></a> [root\_ca\_pem](#output\_root\_ca\_pem) | Public certificate of the private root CA, in PEM format. |
<!-- END_TF_DOCS -->
