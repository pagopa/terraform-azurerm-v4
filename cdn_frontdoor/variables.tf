############################################################
# Core naming, location, RG, tags
############################################################
variable "cdn_prefix_name" {
  type        = string
  description = "Base prefix used to derive the Front Door profile, endpoint, and related resource names (for example myprefix-web). When storage_account_name is null the module appends -sa to this prefix and removes hyphens to build the Storage Account name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that hosts the Front Door profile, storage account, DNS artifacts, and supporting resources."
}

variable "location" {
  type        = string
  description = "Azure region for regional resources such as the storage account; the Front Door service itself is global."
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to every resource created by this module."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Azure AD tenant ID used when granting the Front Door managed identity access to Key Vault certificates; required when keyvault_id is provided."
}

############################################################
# Front Door profile
############################################################

variable "frontdoor_sku_name" {
  type        = string
  description = "Azure Front Door SKU to deploy, for example Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  default     = "Standard_AzureFrontDoor"
}

############################################################
# Storage configuration (static website)
############################################################
variable "storage_account_name" {
  type        = string
  default     = null
  description = "Optional Storage Account name for the static website origin. Must be globally unique; defaults to the prefix plus -sa with hyphens removed."
}

variable "storage_account_advanced_threat_protection_enabled" {
  type        = bool
  default     = false
  description = "Enable Microsoft Defender for Storage (advanced threat protection) on the storage account."
}

variable "storage_account_nested_items_public" {
  type        = bool
  default     = true
  description = "Controls allow_nested_items_to_be_public; set to false to prevent nested blobs from inheriting public access."
}

variable "storage_account_kind" {
  type        = string
  default     = "StorageV2"
  description = "Storage account kind, typically StorageV2 for static website hosting."
}

variable "storage_account_tier" {
  type        = string
  default     = "Standard"
  description = "Performance tier for the storage account (Standard or Premium)."
}

variable "storage_account_replication_type" {
  type        = string
  default     = "ZRS"
  description = "Replication strategy for the storage account, for example ZRS, LRS, or GRS."
}

variable "storage_access_tier" {
  type        = string
  default     = "Hot"
  description = "Default blob access tier for the storage account (Hot or Cool)."
}

variable "storage_public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether the storage account allows public network access; must remain true for Front Door to reach the static website origin."
}

variable "storage_account_index_document" {
  type        = string
  description = "Name of the default document served by the static website (for example index.html)."
}

variable "storage_account_error_404_document" {
  type        = string
  description = "Name of the document returned for 404 responses (for example error.html)."
}

############################################################
# Diagnostics
############################################################
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID that collects Front Door diagnostics and metrics."
}

############################################################
# Routing and caching defaults
############################################################
variable "querystring_caching_behaviour" {
  type        = string
  default     = "IgnoreQueryString"
  description = "Default query string caching behavior applied to the catch-all route (for example IgnoreQueryString)."
}

variable "https_rewrite_enabled" {
  type        = bool
  default     = true
  description = "Enable automatic HTTP to HTTPS redirection on the default route."
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
  description = "List of custom domain definitions to onboard to Front Door, including DNS zone details and optional TTL or record-management flags."
}

############################################################
# Key Vault (certificates for apex domains)
############################################################
variable "keyvault_id" {
  type        = string
  default     = null
  description = "Resource ID of the Key Vault that stores customer-managed certificates for apex domains; required when using your own certificates."
}

############################################################
# Rules inputs
############################################################
variable "global_delivery_rules" {
  type = list(object({
    order                          = number
    cache_expiration_actions       = optional(list(object({ behavior = string, duration = string })), [])
    cache_key_query_string_actions = optional(list(object({ behavior = string, parameters = string })), [])
    modify_request_header_actions  = optional(list(object({ action = string, name = string, value = string })), [])
    modify_response_header_actions = optional(list(object({ action = string, name = string, value = string })), [])
  }))
  default     = []
  description = "Global delivery rules applied to every request, supporting header mutations and cache or query string overrides."
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
  default     = []
  description = "Rules that match URL paths to override caching behavior and optionally set a response header (for example custom TTLs)."
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
  default     = []
  description = "Rules that trigger URL redirects based on the incoming request scheme, such as forcing HTTPS."
}

variable "delivery_rule_redirects" {
  type = list(object({
    name              = string
    order             = number
    behavior_on_match = string

    # conditions
    request_uri_conditions = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_path_conditions    = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])

    # actions
    url_redirect_actions = list(object({ redirect_type = string, protocol = string, hostname = string, path = string, fragment = string, query_string = string }))
  }))
  default     = []
  description = "Ordered redirect rules with optional URI or path conditions and one or more redirect actions."
}

variable "delivery_rule_rewrites" {
  type = list(object({
    name              = string
    order             = number
    behavior_on_match = optional(string)

    request_uri_conditions        = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_file_extension_conditions = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])
    url_path_conditions           = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])

    url_rewrite_actions = optional(list(object({ source_pattern = string, destination = string, preserve_unmatched_path = string })), [])
  }))
  default     = []
  description = "Ordered URL rewrite rules evaluated without client redirects, driven by URI, path, or file conditions."
}

variable "delivery_custom_rules" {
  type = list(object({
    name              = string
    order             = number
    behavior_on_match = optional(string)

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
  default     = []
  description = "Advanced custom rules supporting the full Front Door condition and action set for headers, caching, and mutually exclusive redirects or rewrites."

  validation {
    condition = alltrue([
      for r in var.delivery_custom_rules :
      !(length(try(r.url_redirect_actions, [])) > 0 && length(try(r.url_rewrite_actions, [])) > 0)
    ])
    error_message = "A delivery_rule cannot define both url_redirect_actions and url_rewrite_actions at the same time."
  }
}
