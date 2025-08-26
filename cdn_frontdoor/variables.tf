############################################################
# Core naming, location, RG, tags
############################################################
variable "cdn_prefix_name" {
  type        = string
  description = "Prefix used for naming resources (e.g. myprefix-myapp)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where the Front Door profile will be created."
}

variable "location" {
  type        = string
  description = "Primary location (e.g., westeurope)."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
}

############################################################
# Front Door profile
############################################################
variable "frontdoor_sku_name" {
  type        = string
  description = "SKU name for the Azure Front Door profile."
  default     = "Standard_AzureFrontDoor"
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Tenant ID for KV access policy."
}

############################################################
# Storage configuration (static website)
############################################################
variable "storage_account_name" {
  type        = string
  default     = null
  description = "Optional storage account name; if null, computed from prefix."
}

variable "storage_account_advanced_threat_protection_enabled" {
  type    = bool
  default = false
}

variable "storage_account_nested_items_public" {
  type        = bool
  default     = true
  description = "Reflects 'allow_nested_items_to_be_public' on the storage account."
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
  description = "Enable public network for the storage account."
}

variable "storage_account_index_document" {
  type        = string
  description = "Index document for static website."
}

variable "storage_account_error_404_document" {
  type        = string
  description = "404 document for static website."
}

############################################################
# Diagnostics
############################################################
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace id to send Front Door logs/metrics."
}

############################################################
# Routing and caching defaults
############################################################
variable "querystring_caching_behaviour" {
  type    = string
  default = "IgnoreQueryString"
}

variable "https_rewrite_enabled" {
  type    = bool
  default = true
}

############################################################
# Multi-domain inputs (only)
############################################################
variable "custom_domains" {
  type = list(object({
    domain_name             = string
    dns_name                = string
    dns_resource_group_name = string
    ttl                     = optional(number, 3600)
    enable_dns_records      = optional(bool, true)
  }))
  default     = []
  description = "List of custom domains."
}

############################################################
# Key Vault (certificates for apex domains)
############################################################
variable "keyvault_id" {
  type        = string
  default     = null
  description = "Key Vault ID containing certificates (used for apex domains)."
}

############################################################
# Rules inputs
############################################################
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

variable "delivery_rule_redirects" {
  type = list(object({
    name  = string
    order = number
    behavior_on_match = string

    # conditions
    request_uri_conditions        = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_path_conditions           = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])

    # actions
    url_redirect_actions           = list(object({ redirect_type = string, protocol = string, hostname = string, path = string, fragment = string, query_string = string }))
  }))
  default = []

  validation {
    condition     = contains(["Continue", "Stop"], var.delivery_rule_redirects[*].behavior_on_match...)
    error_message = "behavior_on_match deve essere 'Continue' oppure 'Stop'."
  }
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

variable "delivery_custom_rules" {
  type = list(object({
    name  = string
    order = number

    cookies_conditions            = optional(list(object({ selector = string, operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    device_conditions             = optional(list(object({ operator = string, match_values = string, negate_condition = bool })), [])
    http_version_conditions       = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool })), [])
    post_arg_conditions           = optional(list(object({ selector = string, operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    query_string_conditions       = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    remote_address_conditions     = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool })), [])
    request_body_conditions       = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    request_header_conditions     = optional(list(object({ selector = string, operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    request_method_conditions     = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool })), [])
    request_scheme_conditions     = optional(list(object({ operator = string, match_values = string, negate_condition = bool })), [])
    request_uri_conditions        = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_file_extension_conditions = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_file_name_conditions      = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_path_conditions           = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])

    cache_expiration_actions       = optional(list(object({ behavior = string, duration = string })), [])
    cache_key_query_string_actions = optional(list(object({ behavior = string, parameters = string })), [])
    modify_request_header_actions  = optional(list(object({ action = string, name = string, value = string })), [])
    modify_response_header_actions = optional(list(object({ action = string, name = string, value = string })), [])
    url_redirect_actions           = optional(list(object({ redirect_type = string, protocol = string, hostname = string, path = string, fragment = string, query_string = string })), [])
    url_rewrite_actions            = optional(list(object({ source_pattern = string, destination = string, preserve_unmatched_path = string })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.delivery_custom_rules :
      !(length(try(r.url_redirect_actions, [])) > 0 && length(try(r.url_rewrite_actions, [])) > 0)
    ])
    error_message = "A delivery_rule cannot define both url_redirect_actions and url_rewrite_actions at the same time."
  }
}
