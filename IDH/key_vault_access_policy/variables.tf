variable "product_name" {
  description = "product_name used to identify the platform or workload associated with the resource"
  type        = string
}

variable "idh_resource_tier" {
  description = "Permission tier to apply: admin, developer, external"
  type        = string
}

variable "env" {
  description = "Target environment for the deployment: dev, prod, uat, etc."
  type        = string
}

variable "key_vault_id" {
  description = "Azure Key Vault ID where the access policy will be applied"
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID"
  type        = string
}

variable "object_id" {
  description = "Object ID of the Azure AD group or identity to which the policy will be assigned"
  type        = string
}
