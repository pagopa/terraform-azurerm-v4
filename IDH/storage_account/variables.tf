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
  description = "(Required) The name od IDH resource key to be created."
}

variable "location" {
  type        = string
  description = "(Required) region where the storage account will be created"
}

variable "name" {
  type        = string
  description = "(Required) storage account name. Dashes and underscore will be removed. Max 24 chars"
}

variable "domain" {
  type        = string
  description = "(Optional) Specifies the domain of the Storage Account."
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "(Required) Resource group name where to save the storage account"
}

variable "enable_identity" {
  description = "(Optional) If true, set the identity as SystemAssigned"
  type        = bool
  default     = false
}

variable "network_rules" {
  type = object({
    default_action             = string       # Specifies the default action of allow or deny when no other rules match. Valid options are Deny or Allow
    bypass                     = set(string)  # Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None
    ip_rules                   = list(string) # List of public IP or IP ranges in CIDR Format. Only IPV4 addresses are allowed
    virtual_network_subnet_ids = list(string) # A list of resource ids for subnets.
  })
  default = null

  validation {
    condition     = var.network_rules != null ? var.network_rules.default_action == "Deny" : true
    error_message = "If network_rules is set, default_action must be set to Deny"
  }

  validation {
    condition     = var.network_rules != null ? length(var.network_rules.ip_rules) > 0 || length(var.network_rules.virtual_network_subnet_ids) > 0 : true
    error_message = "If network_rules is set, one of either ip_rules or virtual_network_subnet_ids must be specified"
  }
}

variable "tags" {
  type = map(any)
}

variable "index_document" {
  type        = string
  default     = null
  description = "The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive."
}

variable "error_404_document" {
  type        = string
  default     = null
  description = "The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file."
}

variable "custom_domain" {
  type = object({
    name          = string
    use_subdomain = bool
  })
  description = "Custom domain for accessing blob data"
  default = {
    name          = null
    use_subdomain = false
  }
}

# -------------------
# Immutability Policy
# -------------------
variable "immutability_policy" {
  type = object({
    enabled                       = bool
    allow_protected_append_writes = optional(bool, false)
    period_since_creation_in_days = optional(number, 730)
  })
  description = "Properties to setup the immutability policy. The resource can be created only with \"Disabled\" and \"Unlocked\" state. Change to \"Locked\" state doens't update the resource for a bug of the current module."
  default = {
    enabled                       = false
    allow_protected_append_writes = false
    period_since_creation_in_days = 730
  }

  # https://learn.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview#limitations-and-known-issues
  validation {
    condition     = var.immutability_policy.enabled ? !module.idh_loader.point_in_time_restore_enabled : true
    error_message = "Point in Time restore must be disabled when using immutability policy. use another idh_resource_tier"
  }
}


variable "replication_type" {
  type        = string
  default     = null
  description = "(Optional) storage account replication type. Default is the minimum replication type for the environment."

  validation {
    condition     = var.replication_type != null ? try(local.allowed_replication_types[var.replication_type], -1) >= lookup(local.allowed_replication_types, module.idh_loader.idh_resource_configuration.min_account_replication_type, 0) : true
    error_message = "The replication type '${coalesce(var.replication_type, module.idh_loader.idh_resource_configuration.min_account_replication_type)}' is not allowed in '${var.env}' environment for idh resource '${var.idh_resource_tier}'. The minimum replication type is '${module.idh_loader.idh_resource_configuration.min_account_replication_type}'. Valid values are ${local.allowed_replication_types_string}"
  }
}

# -------------------
# Alerts variables
# -------------------


variable "low_availability_threshold" {
  type        = number
  description = "The Low Availability threshold. If metric average is under this value, the alert will be triggered. Default is 99.8"
  default     = 99.8
}

variable "action" {
  description = "The ID of the Action Group and optional map of custom string properties to include with the post webhook operation."
  type = set(object(
    {
      action_group_id    = string
      webhook_properties = map(string)
    }
  ))
  default = []
}


# Private Endpoint



variable "private_dns_zone_blob_ids" {
  type        = list(string)
  description = "Used only for private endpoints"
  default     = []
}

variable "private_dns_zone_table_ids" {
  type        = list(string)
  description = "Used only for private endpoints"
  default     = []
}

variable "private_dns_zone_queue_ids" {
  type        = list(string)
  description = "Used only for private endpoints"
  default     = []
}

variable "private_dns_zone_file_ids" {
  type        = list(string)
  description = "Used only for private endpoints"
  default     = []
}

variable "private_dns_zone_web_ids" {
  type        = list(string)
  description = "Used only for private endpoints"
  default     = []
}

variable "private_dns_zone_dfs_ids" {
  type        = list(string)
  description = "Used only for private endpoints"
  default     = []
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Used only for private endpoints"
  default     = null
}
