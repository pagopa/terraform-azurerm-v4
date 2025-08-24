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

variable "cdn_location" {
  type        = string
  default     = null
  description = "If the location of the CDN needs to be different from that of the storage account, set this variable to the location where the CDN should be created. For example, cdn_location = westeurope and location = northitaly"
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

variable "frontdoor_sku_name" {
  type        = string
  description = "SKU name for the Azure Front Door profile"
  default     = "Standard_AzureFrontDoor"
}


#
# KV
#
# variable "keyvault_resource_group_name" {
#   type        = string
#   description = "Key vault resource group name"
# }
#
# variable "keyvault_vault_name" {
#   type        = string
#   description = "Key vault name"
# }

variable "keyvault_id" {
  type        = string
  description = "Key vault id"
  default     = null
}

#
# Storage
#
variable "storage_account_name" {
  type        = string
  description = "(Optional) The storage account name used by the CDN"
  default     = null
}

variable "storage_account_advanced_threat_protection_enabled" {
  type    = bool
  default = false
}

variable "storage_account_nested_items_public" {
  type        = bool
  default     = true
  description = "(Optional) reflects to property 'allow_nested_items_to_be_public' on storage account module"
}

variable "storage_account_kind" {
  type    = string
  default = "StorageV2"
}

variable "storage_account_tier" {
  type    = string
  default = "Standard"
}

variable "storage_account_replication_type" {
  type    = string
  default = "ZRS"
}

variable "storage_access_tier" {
  type    = string
  default = "Hot"
}

variable "storage_public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Flag to set public public network for storage account"
}

#
# Logs
#
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace id to send logs to"
}

#
# Rules
#
variable "global_delivery_rules" {
  type = list(object({
    order                         = number
    cache_expiration_action       = optional(list(object({ behavior = string, duration = string })), [])
    cache_key_query_string_action = optional(list(object({ behavior = string, parameters = string })), [])
    modify_request_header_action  = optional(list(object({ action = string, name = string, value = string })), [])
    modify_response_header_action = optional(list(object({ action = string, name = string, value = string })), [])
  }))
  default = []
}


variable "delivery_rule_url_path_condition_cache_expiration_action" {
  type = list(object({
    name            = string
    order           = number
    operator        = string
    match_values    = list(string)
    behavior        = string
    duration        = string
    response_action = string
    response_name   = string
    response_value  = string
  }))
  default = []
}

variable "delivery_rule_request_scheme_condition" {
  type = list(object({
    name         = string
    order        = number
    operator     = string
    match_values = list(string)
    url_redirect_action = object({
      redirect_type = string
      protocol      = string
      hostname      = string
      path          = string
      fragment      = string
      query_string  = string
    })
  }))
  default = []
}

variable "delivery_rule_redirect" {
  type = list(object({
    name         = string
    order        = number
    operator     = string
    match_values = list(string)
    url_redirect_action = object({
      redirect_type = string
      protocol      = string
      hostname      = string
      path          = string
      fragment      = string
      query_string  = string
    })
  }))
  default = []
}

variable "delivery_rule_rewrite" {
  type = list(object({
    name  = string
    order = number
    conditions = list(object({
      condition_type   = string
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    }))
    url_rewrite_action = object({
      source_pattern          = string
      destination             = string
      preserve_unmatched_path = string
    })
  }))
  default = []
}

variable "delivery_rule" {
  type = list(object({
    name  = string
    order = number

    # start conditions
    cookies_conditions          = optional(list(object({
      selector         = string
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    device_conditions           = optional(list(object({
      operator         = string
      match_values     = string
      negate_condition = bool
    })), [])

    http_version_conditions     = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
    })), [])

    post_arg_conditions         = optional(list(object({
      selector         = string
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    query_string_conditions     = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    remote_address_conditions   = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
    })), [])

    request_body_conditions     = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    request_header_conditions   = optional(list(object({
      selector         = string
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    request_method_conditions   = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
    })), [])

    request_scheme_conditions   = optional(list(object({
      operator         = string
      match_values     = string
      negate_condition = bool
    })), [])

    request_uri_conditions      = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    url_file_extension_conditions = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    url_file_name_conditions   = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])

    url_path_conditions        = optional(list(object({
      operator         = string
      match_values     = list(string)
      negate_condition = bool
      transforms       = list(string)
    })), [])
    # end conditions

    # start actions
    cache_expiration_actions   = optional(list(object({
      behavior = string
      duration = string
    })), [])

    cache_key_query_string_actions = optional(list(object({
      behavior   = string
      parameters = string
    })), [])

    modify_request_header_actions = optional(list(object({
      action = string
      name   = string
      value  = string
    })), [])

    modify_response_header_actions = optional(list(object({
      action = string
      name   = string
      value  = string
    })), [])

    url_redirect_actions = optional(list(object({
      redirect_type = string
      protocol      = string
      hostname      = string
      path          = string
      fragment      = string
      query_string  = string
    })), [])

    url_rewrite_actions = optional(list(object({
      source_pattern          = string
      destination             = string
      preserve_unmatched_path = string
    })), [])
    # end actions
  }))
  default = []
}

#
# CDN Configuration
#
variable "querystring_caching_behaviour" {
  type    = string
  default = "IgnoreQueryString"
}

variable "https_rewrite_enabled" {
  type    = bool
  default = true
}

variable "hostname" {
  type = string
  default = ""
}

variable "storage_account_index_document" {
  type = string
}

variable "storage_account_error_404_document" {
  type = string
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
