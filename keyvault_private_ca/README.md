# keyvault_private_ca

Terraform module for managing a private CA on Azure Key Vault with automatic issuance and renewal of mTLS client certificates.

## How it works

1. Creates an Azure Key Vault (Premium SKU, HSM-backed)
2. Issues a self-signed Root CA (4096-bit RSA, 10 years, non-exportable)
3. Issues client certificates signed by the CA with configurable auto-renewal

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
  key_vault_name      = "${local.project}-kv-ca-${var.env_short}"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  certificate_officer_principal_ids = [
    data.azurerm_user_assigned_identity.payments_workload_identity.principal_id,
  ]

  certificates = {
    "pagopa-ente-alfa-client" = {
      subject            = "CN=pagopa-ente-alfa-client,O=PagoPA S.p.A.,C=IT"
      validity_in_months = 3
      days_before_expiry = 30
      san_dns_names      = []
    }
  }

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

variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD Tenant ID"
}

variable "certificate_officer_principal_ids" {
  type        = list(string)
  description = "List of principal IDs (managed identity, service principal) with the Key Vault Certificates Officer role"
  default     = []
}

variable "certificates" {
  description = "Map of client certificates to be issued"
  type = map(object({
    subject            = string
    validity_in_months = number
    days_before_expiry = number
    san_dns_names      = optional(list(string), [])
  }))
  default = {}
}

variable "root_subject" {
    type        = string
    description = "Subject of the Root CA (e.g., 'CN=PagoPA Private Root CA,O=PagoPA S.p.A.,C=IT')"
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

## Estimated costs

| Item | Cost |
|---|---|
| Automatic certificate renewal | $3/renewal |
| Other operations (get, list, update) | $0.03/10,000 ops |
| 10 certs (3-month validity) | ~$120/year |
| 10 certs (6-month validity) | ~$60/year |