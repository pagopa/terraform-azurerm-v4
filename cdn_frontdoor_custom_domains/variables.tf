variable "cdn_prefix_name" {
  type        = string
  description = "Prefix used for naming resources (e.g. myprefix-myapp)"
}

variable "tenant_id" {
  type    = string
  default = null
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "resource_group_name" {
  type = string
}

variable enable_custom_domain {
  type    = bool
  default = true
  description = "Enable the custom domain configuration on the Front Door"
}


#
# KV
#

variable "keyvault_id" {
  type        = string
  description = "Key vault id"
  default     = null
}

variable "hostname" {
  type = string
  default = ""
}

variable "custom_hostname_kv_enabled" {
  type        = bool
  default     = false
  description = "Flag required to enable the association between KV certificate and CDN when the hostname is different from the APEX"
}

variable "dns_zone_name" {
  type = string
  default = ""
}

variable "dns_zone_resource_group_name" {
  type = string
  default = ""
}

variable "create_dns_record" {
  type    = bool
  default = true
}
