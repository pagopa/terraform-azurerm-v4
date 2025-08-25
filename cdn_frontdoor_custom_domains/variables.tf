variable "cdn_prefix_name" {
  type        = string
  description = "Prefix for Front Door naming (e.g. myapp-prod)."
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group of the Front Door profile."
}

variable "keyvault_id" {
  type        = string
  default     = null
  description = "Key Vault ID containing certificates."
}

variable "custom_domains" {
  type = list(object({
    domain_name             = string
    dns_name                = string
    dns_resource_group_name = string
    enable_dns_records      = optional(bool, true)
  }))
  default     = []
  description = "List of custom domains with DNS zone and per-domain control for DNS records."
}
