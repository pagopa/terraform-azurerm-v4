variable "product_name" {
  type        = string
  description = "(Required) product_name used to identify the platform for which the resource will be created"
  validation {
    condition = (
      length(var.product_name) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type        = string
  description = "(Required) Environment for which the resource will be created"
}

variable "idh_resource_tier" {
  type        = string
  description = "(Required) The name of IDH resource tier to be created. See LIBRARY.md for available tiers."
}

variable "location" {
  type        = string
  description = "(Required) The Azure location where the managed Redis instance will be created."
}

variable "name" {
  type        = string
  description = "(Required) The name of the managed Redis instance."
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 63
    error_message = "The name must be between 1 and 63 characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group where the managed Redis instance will be created."
}

variable "tags" {
  type        = map(string)
  description = "(Required) Tags to apply to the managed Redis instance and related resources."
}

# -----------------------------------------------
# Runtime Overrides (optional)
# -----------------------------------------------


variable "modules_override" {
  type = list(object({
    name = string
  }))
  description = "(Optional) Override the modules list from tier configuration. Useful to add/modify modules like RediSearch, RedisJSON, etc."
  default     = null
}

variable "eviction_policy_override" {
  type        = string
  description = "(Optional) Override the eviction policy from tier configuration. Valid values: AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, NoEviction"
  default     = null
  validation {
    condition = var.eviction_policy_override == null || contains([
      "AllKeysLFU",
      "AllKeysLRU",
      "AllKeysRandom",
      "VolatileLFU",
      "VolatileLRU",
      "VolatileRandom",
      "VolatileTTL",
      "NoEviction"
    ], var.eviction_policy_override)
    error_message = "If provided, eviction policy must be one of: AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, NoEviction."
  }
}

# -----------------------------------------------
# Network Configuration
# -----------------------------------------------
variable "embedded_subnet" {
  type = object({
    enabled              = bool
    vnet_name            = optional(string, null)
    vnet_rg_name         = optional(string, null)
    private_dns_zone_ids = optional(list(string), [])
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the managed Redis private endpoint. When enabled, 'private_endpoint_subnet_id' must be null."
  default = {
    enabled              = false
    vnet_name            = null
    vnet_rg_name         = null
    private_dns_zone_ids = []
  }

  validation {
    condition     = var.embedded_subnet.enabled ? (var.embedded_subnet.vnet_name != null && var.embedded_subnet.vnet_rg_name != null) : true
    error_message = "If 'embedded_subnet' is enabled, both 'vnet_name' and 'vnet_rg_name' must be provided."
  }

  validation {
    condition     = var.embedded_subnet.enabled && length(var.embedded_subnet.private_dns_zone_ids) > 0 ? true : !var.embedded_subnet.enabled ? true : false
    error_message = "If 'embedded_subnet' is enabled and private endpoint is required, 'private_dns_zone_ids' must contain at least one DNS zone ID."
  }
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "(Optional) The subnet ID for the private endpoint. Required if private endpoint is enabled and embedded_subnet is not used."
  default     = null
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "(Optional) The list of private DNS zone IDs for the private endpoint."
  default     = []
}

# -----------------------------------------------
# Encryption & Security
# -----------------------------------------------
variable "customer_managed_key_config" {
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  description = "(Optional) Customer managed key configuration for encryption at rest."
  default     = null
}

# -----------------------------------------------
# Monitoring & Alerts
# -----------------------------------------------
variable "alert_action_group_ids" {
  type        = list(string)
  description = "(Optional) List of Azure Monitor action group IDs for alerts."
  default     = []
}

# -----------------------------------------------
# NSG Configuration
# -----------------------------------------------
variable "resource_group_nsg_name" {
  type        = string
  description = "(Optional) The name of the nsg Resource Group."
  default     = ""
}

variable "nsg_flow_log_configuration" {
  type = object({
    enabled                    = bool
    network_watcher_name       = optional(string, null)
    network_watcher_rg         = optional(string, null)
    storage_account_id         = optional(string, null)
    traffic_analytics_law_name = optional(string, null)
    traffic_analytics_law_rg   = optional(string, null)
  })
  description = "(Optional) NSG flow log configuration"
  default = {
    enabled = false
  }
}

variable "embedded_nsg_configuration" {
  type = object({
    source_address_prefixes      = list(string)
    source_address_prefixes_name = string
  })
  description = "(Optional) List of allowed CIDR and name for NSG rules."
  default = {
    source_address_prefixes      = ["*"]
    source_address_prefixes_name = "All"
  }
}

# -----------------------------------------------
# Geo-Replication Replica Configuration
# -----------------------------------------------
variable "geo_replication" {
  type = object({
    enabled      = bool
    subnet_id    = optional(string, null)
    location     = optional(string, null)
    vnet_rg_name = optional(string, null)
    vnet_name    = optional(string, null)
  })
  default = {
    enabled      = false
    subnet_id    = null
    location     = null
    vnet_rg_name = null
    vnet_name    = null
  }
  description = "(Optional) Map of geo replication settings"

  validation {
    condition     = !module.idh_loader.idh_resource_configuration.geo_replication_allowed ? var.geo_replication.enabled == false : true
    error_message = "Geo replication is not allowed in '${var.env}' environment for '${var.idh_resource_tier}'"
  }

  validation {
    error_message = "If geo_replication is enabled, 'name' and 'location' must be provided"
    condition     = var.geo_replication.enabled ? (var.geo_replication.name != null && var.geo_replication.location != null) : true
  }
}

