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

Renewal of the current certificate is automatic: `time_rotating.cert_rotation` fires after `validity_months * 30 - renewal_days_before_expiry` days and renews `-pfx` on the next apply.

Promotion `-pfx` → `-stable-*` is manual and driven by the module variable `stable_promotion_ids` (certificate name → promotion id), passed by pipelines at apply time. Any string of letters, digits, `.`, `_` or `-` is accepted; a build id is a good choice: it is new on every run and traces who promoted and when.

| Promotion id of the certificate | Effect on apply |
|---|---|
| not passed | Nothing is promoted, even if `-pfx` was renewed in the meantime |
| same id as the last promotion | Nothing is promoted |
| new id | `-pfx` is promoted to `-stable-*` |

Only the listed certificates are promoted. If a promotion fails, the resource stays tainted and the next apply retries it.

> [!IMPORTANT]
> The first deploy of a certificate must always pass its promotion id (e.g. `-var 'stable_promotion_ids={"cert-a":"$(Build.BuildId)"}'`): without it, the certificate is issued but no `-stable-*` secret is created, and clients reading them fail. The certificate issued in that same apply is the one promoted.

The stack declares the variable and passes it to the module:

```hcl
variable "stable_promotion_ids" {
  type    = map(string)
  default = {}
}

module "keyvault_client_certificates" {
  ...
  stable_promotion_ids = var.stable_promotion_ids
}
```

The same mechanism serves two flows; the module does not change, only who decides which certificates to promote:

| Flow | Who decides | Apply |
|---|---|---|
| On-demand pipeline | An operator, choosing one certificate (e.g. after the renewal e-mail) | `terraform apply -var 'stable_promotion_ids={"cert-a":"$(Build.BuildId)"}'` |
| Scheduled pipeline | A rule in the pipeline (e.g. stable expiring within N days) | Same command, listing only the certificates matching the rule |

Things to know:

- **Plan noise after a promotion.** The next run without the variable turns that certificate's id back to `null`: the plan shows `client_cert_stable["<name>"]` replaced, but nothing is promoted.
- **Promotion and renewal share the apply.** If the renewal of the same certificate is due in the promotion run, the new `-pfx` is issued and promoted at once, before anyone was notified. Promotion pipelines should save the plan (`terraform plan -out=tfplan`), inspect it (`terraform show -json tfplan`) and stop if it changes anything other than the `client_cert_stable` instances being promoted — in particular any `client_cert_sign`.
- **Concurrent runs.** The renewal and promotion pipelines share the state: the backend lock rejects the second concurrent apply, so avoid scheduling them at the same time.
- **Checking current vs stable.** `scripts/check_cert_promotion.sh` tells whether `-pfx` and `-stable-*` hold the same certificate (exit `0`) or the current was renewed and not promoted yet (exit `1`).

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
    }
    "pagopa-forwarder" = {
      key_vault_name             = module.kv_forwarder.name
      subject                    = "CN=pagopa-forwarder,O=PagoPA S.p.A.,C=IT"
      validity_in_months         = 12
      renewal_days_before_expiry = 50
      san_dns_names              = ["forwarder.internal.pagopa.it"]
    }
  }

  # Promotion ids passed by pipelines, e.g. {"my-service" = "<build id>"}
  stable_promotion_ids = var.stable_promotion_ids

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
| [azurerm_key_vault_certificate.root_ca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of client certificates to be issued. Promotion to the stable secrets is driven by stable\_promotion\_ids. | <pre>map(object({<br/>    key_vault_name             = string<br/>    subject                    = string<br/>    validity_in_months         = number<br/>    san_dns_names              = optional(list(string), [])<br/>    renewal_days_before_expiry = optional(number, 60)<br/>    # For testing only: overrides rotation_days with rotation_minutes<br/>    rotation_minutes_override = optional(number, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_root_key_vault_id"></a> [root\_key\_vault\_id](#input\_root\_key\_vault\_id) | ID of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_root_key_vault_name"></a> [root\_key\_vault\_name](#input\_root\_key\_vault\_name) | Name of the Key Vault containing the Root CA (source) | `string` | n/a | yes |
| <a name="input_stable_promotion_ids"></a> [stable\_promotion\_ids](#input\_stable\_promotion\_ids) | Promotion ids by certificate name, passed by pipelines at apply time (e.g. -var 'stable\_promotion\_ids={"my-cert":"<build id>"}'): a certificate (<name>-pfx) is promoted to its stable secrets (<name>-stable-*) when its id changes. Runs omitting it never promote: the first deploy of a certificate must list it, otherwise no -stable-* secret is created. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
