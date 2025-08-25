variable "cdn_prefix_name" {
  type        = string
  description = "Prefix for Front Door naming (e.g. myapp-prod)."
}

variable "cdn_route_id" {
  type        = string
  description = "ID della route Front Door a cui associare tutti i custom domains."
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group of the Front Door profile."
}

variable "keyvault_id" {
  type        = string
  description = "Key Vault ID containing certificates."
}

variable "custom_domains" {
  type = list(object({
    domain_name             = string
    dns_name                = string
    dns_resource_group_name = string
    ttl                     = optional(number, 3600)
    enable_dns_records      = optional(bool, true)
  }))
  description = "List of custom domains with DNS zone and per-domain control for DNS records."
}
