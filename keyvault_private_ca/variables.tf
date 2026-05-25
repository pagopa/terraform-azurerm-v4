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
  description = "Name of the prefix Key Vault"
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