############################################################
# Core Infrastructure
############################################################
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostics"
}

############################################################
# CDN Profile
############################################################
variable "profile" {
  type = object({
    name = string
  })
  description = "CDN Front Door profile configuration"

  # validation {
  #   condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.profile.sku)
  #   error_message = "Profile SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  # }
}

############################################################
# Endpoints
############################################################
variable "endpoints" {
  type = map(object({
    name = optional(string)
  }))

  description = "CDN Front Door endpoints (entry points)"

  validation {
    condition     = length(var.endpoints) > 0
    error_message = "At least one endpoint must be defined"
  }
}

############################################################
# Origins
############################################################
variable "origins" {
  type = map(object({
    host_name          = string
    type               = string
    http_port          = optional(number, 80)
    https_port         = optional(number, 443)
    origin_host_header = optional(string)
    priority           = optional(number, 1)
    weight             = optional(number, 1000)
    enabled            = optional(bool, true)
  }))

  description = "Backend origins (servers/services)"

  validation {
    condition = alltrue([
      for origin in values(var.origins) :
      contains(["storage", "app_service", "function", "custom"], origin.type)
    ])
    error_message = "Origin type must be one of: storage, app_service, function, custom"
  }

  validation {
    condition = alltrue([
      for origin in values(var.origins) :
      origin.host_name != null && length(trim(origin.host_name, " ")) > 0
    ])
    error_message = "All origins must have a non-empty host_name"
  }
}

############################################################
# Origin Groups
############################################################
variable "origin_groups" {
  type = map(object({
    description = optional(string, "")
    members     = list(string)

    health_probe = optional(object({
      path                = optional(string, "/")
      protocol            = optional(string, "Https")
      request_type        = optional(string, "GET")
      interval_in_seconds = optional(number, 120)
    }), {})

    load_balancing = optional(object({
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 2)
      additional_latency_in_milliseconds = optional(number, 0)
    }), {})
  }))

  description = "Origin groups (pools of backends with health checks and load balancing)"

  validation {
    condition = alltrue([
      for og in values(var.origin_groups) :
      alltrue([
        for origin_ref in og.members :
        contains(keys(var.origins), origin_ref)
      ])
    ])
    error_message = "All origins referenced by origin_groups must exist in var.origins"
  }

  validation {
    condition = alltrue([
      for og_key, og in var.origin_groups :
      length(og.members) > 0 || (try(var.storage_account.enabled, false) && try(var.storage_account.origin_group, null) == og_key)
    ])
    error_message = "Each origin_group must have at least one member (unless it is the target origin_group of an enabled static-website storage account)"
  }
}

############################################################
# Routes
############################################################
variable "routes" {
  type = map(object({
    endpoint       = string
    origin_group   = string
    patterns       = list(string)
    protocols      = optional(list(string), ["Http", "Https"])
    forwarding     = optional(string, "MatchRequest")
    https_redirect = optional(bool, true)
    cache_behavior = optional(string, "IgnoreQueryString")
    custom_domains = optional(list(string), [])
    rulesets       = optional(list(string), [])
    enabled        = optional(bool, true)
  }))

  description = "Routes (connect endpoints → origin_groups, apply rulesets, attach domains)"

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      contains(keys(var.endpoints), route.endpoint)
    ])
    error_message = "All routes must reference endpoints that exist in var.endpoints"
  }

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      contains(keys(var.origin_groups), route.origin_group)
    ])
    error_message = "All routes must reference origin_groups that exist in var.origin_groups"
  }

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      alltrue([
        for ruleset_name in try(route.rulesets, []) :
        contains(keys(var.rulesets), ruleset_name)
      ])
    ])
    error_message = "All rulesets referenced by routes must exist in var.rulesets"
  }

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      alltrue([
        for domain_name in try(route.custom_domains, []) :
        contains(keys(var.custom_domains), domain_name)
      ])
    ])
    error_message = "All custom_domains referenced by routes must exist in var.custom_domains"
  }

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      contains(["IgnoreQueryString", "UseQueryString", "IncludeSpecifiedQueryStrings", "IgnoreSpecifiedQueryStrings"], route.cache_behavior)
    ])
    error_message = "Route cache_behavior must be: IgnoreQueryString, UseQueryString, IncludeSpecifiedQueryStrings, or IgnoreSpecifiedQueryStrings"
  }
}

############################################################
# Rulesets and Rules
############################################################
variable "rulesets" {
  type = map(object({
    description = optional(string, "")
    rules = map(object({
      order             = number
      behavior_on_match = optional(string, "Continue")

      condition = optional(object({
        type         = string
        operator     = string
        match_values = optional(list(string), [])
        negate       = optional(bool, false)
        transforms   = optional(list(string), [])
        selector     = optional(string)
      }))

      conditions = optional(list(object({
        type         = string
        operator     = string
        match_values = optional(list(string), [])
        negate       = optional(bool, false)
        transforms   = optional(list(string), [])
        selector     = optional(string)
      })), [])

      actions = list(object({
        type     = string
        protocol = optional(string)
        hostname = optional(string)
        path     = optional(string)
        fragment = optional(string)

        redirect_type           = optional(string)
        query_string            = optional(string)
        source_pattern          = optional(string)
        destination             = optional(string)
        preserve_unmatched_path = optional(bool, false)

        behavior              = optional(string)
        duration              = optional(string) # d.HH:MM:SS format (e.g. 365.23:59:59)
        query_string_behavior = optional(string)
        query_string_params   = optional(string)

        header_action = optional(string)
        header_name   = optional(string)
        value         = optional(string)
      }))
    }))
  }))

  default     = {}
  description = "Rulesets containing rules for request processing (headers, caching, redirects, rewrites)"

  validation {
    condition = alltrue([
      for ruleset in values(var.rulesets) :
      alltrue([
        for rule in values(ruleset.rules) :
        length(rule.actions) > 0
      ])
    ])
    error_message = "Each rule must have at least one action defined"
  }

  validation {
    condition = alltrue([
      for ruleset in values(var.rulesets) :
      alltrue([
        for rule_name, rule in ruleset.rules :
        # Check no duplicate orders in same ruleset
        length(ruleset.rules) == length(distinct([
          for r in values(ruleset.rules) : r.order
        ]))
      ])
    ])
    error_message = "Rule orders must be unique within each ruleset"
  }

  validation {
    condition = alltrue([
      for ruleset in values(var.rulesets) :
      alltrue([
        for rule in values(ruleset.rules) :
        alltrue([
          for action in rule.actions :
          contains(["redirect", "rewrite", "cache", "request_header", "response_header"], action.type)
        ])
      ])
    ])
    error_message = "Action type must be one of: redirect, rewrite, cache, request_header, response_header"
  }

  validation {
    condition = alltrue([
      for ruleset in values(var.rulesets) :
      alltrue([
        for rule in values(ruleset.rules) :
        !(
          length([for a in rule.actions : a if a.type == "redirect"]) > 0 &&
          length([for a in rule.actions : a if a.type == "rewrite"]) > 0
        )
      ])
    ])
    error_message = "A rule cannot have both redirect and rewrite actions"
  }
}

############################################################
# Custom Domains
############################################################
variable "custom_domains" {
  type = map(object({
    dns_zone_name                = string
    dns_zone_resource_group_name = string
    certificate_type             = optional(string, "Managed")
    keyvault_id                  = optional(string)
    keyvault_certificate_name    = optional(string)
    enable_dns_records           = optional(bool, true)
    ttl                          = optional(number, 3600)
  }))

  default     = {}
  description = "Custom domains with DNS and certificate management"

  validation {
    condition = alltrue([
      for domain in values(var.custom_domains) :
      contains(["ManagedCertificate", "CustomerCertificate"], domain.certificate_type)
    ])
    error_message = "Certificate type must be Managed or CustomerCertificate"
  }

  validation {
    condition = alltrue([
      for domain in values(var.custom_domains) :
      domain.certificate_type != "CustomerCertificate" ||
      (domain.keyvault_id != null && domain.keyvault_certificate_name != null)
    ])
    error_message = "CustomerCertificate type requires keyvault_id and keyvault_certificate_name"
  }
}

############################################################
# Optional: Storage Account for Static Website
############################################################
variable "storage_account" {
  type = object({
    enabled                         = optional(bool, false)
    account_name                    = optional(string)
    account_kind                    = optional(string, "StorageV2")
    account_tier                    = optional(string, "Standard")
    account_replication_type        = optional(string, "ZRS")
    access_tier                     = optional(string, "Hot")
    index_document                  = optional(string, "index.html")
    error_404_document              = optional(string, "error.html")
    nested_items_public             = optional(bool, true)
    public_network_access           = optional(bool, true)
    allow_nested_items_to_be_public = optional(bool, true)
    threat_protection_enabled       = optional(bool, false)
    origin_group                    = optional(string)
  })

  default     = {}
  description = "Optional storage account configuration for static website hosting. Set 'origin_group' to the key of an origin_group to automatically wire the static website as a CDN Front Door origin."
}

############################################################
# Optional: Key Vault for Certificates
############################################################
variable "tenant_id" {
  type        = string
  default     = null
  description = "Tenant ID for Key Vault access (required if using CustomerCertificate domains)"
}
