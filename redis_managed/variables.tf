variable "name" {
  type        = string
  description = "(Required) The name of the Redis instance."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name)) && length(var.name) >= 1 && length(var.name) <= 63
    error_message = "Name must be 1-63 lowercase alphanumerics and hyphens, starting and ending with alphanumeric."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group."
  nullable    = false
}

variable "location" {
  type        = string
  description = "(Required) The Azure region where resources will be created."
  nullable    = false
}

variable "sku_name" {
  type        = string
  description = "(Required) The SKU name for the Managed Redis (Enterprise_E10, Enterprise_E20, etc)."
  nullable    = false

  validation {
    condition     = can(regex("^Enterprise_E(10|20|50|100)$", var.sku_name))
    error_message = "sku_name must be 'Enterprise_E10', 'Enterprise_E20', 'Enterprise_E50', or 'Enterprise_E100'."
  }
}

variable "family" {
  type        = string
  description = "(Required) The SKU family. For Managed Redis, this is typically 'Enterprise'."
  nullable    = false

  validation {
    condition     = var.family == "Enterprise"
    error_message = "family must be 'Enterprise' for Managed Redis."
  }
}

variable "capacity" {
  type        = number
  description = "(Required) The number of replicas for Managed Redis. Valid values: 1-5."
  nullable    = false

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 5
    error_message = "capacity must be between 1 and 5."
  }
}

variable "redis_version" {
  type        = string
  description = "(Required) Redis version ('6' or '7')."
  nullable    = false

  validation {
    condition     = contains(["6", "7"], var.redis_version)
    error_message = "redis_version must be '6' or '7'."
  }
}

variable "enable_non_ssl_port" {
  type        = bool
  description = "(Optional) Enable the non-SSL port (6379). Default is false."
  default     = false
}

variable "minimum_tls_version" {
  type        = string
  description = "(Optional) Minimum TLS version. Valid values: '1.2' or '1.3'. Default is '1.2'."
  default     = "1.2"

  validation {
    condition     = contains(["1.2", "1.3"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be '1.2' or '1.3'."
  }
}

variable "shard_count" {
  type        = number
  description = "(Optional) Number of shards for clustering. Default is 1."
  default     = 1

  validation {
    condition     = var.shard_count >= 1 && var.shard_count <= 10
    error_message = "shard_count must be between 1 and 10."
  }
}

variable "subnet_id" {
  type        = string
  description = "(Required) The Subnet ID within which the Managed Redis should be deployed."
  nullable    = false
}

variable "private_static_ip_address" {
  type        = string
  description = "(Optional) Static IP address for the Managed Redis in the Virtual Network."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "(Optional) Whether public network access is allowed. Default is false."
  default     = false
}

variable "custom_zones" {
  type        = list(number)
  description = "(Optional) List of Availability Zones for high availability. Default is [1,2,3]."
  default     = [1, 2, 3]

  validation {
    condition     = alltrue([for zone in var.custom_zones : zone >= 1 && zone <= 3])
    error_message = "Zones must be 1, 2, or 3."
  }
}

variable "enable_authentication" {
  type        = bool
  description = "(Optional) Enable authentication. Default is true."
  default     = true
}

variable "tags" {
  type        = map(any)
  description = "(Required) Tags to apply to all resources."
  nullable    = false
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "(Optional) Enable private endpoint for secure connectivity. Default is false."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "(Optional) The subnet ID where the private endpoint will be created. Required if private_endpoint_enabled is true."
  default     = null
}

variable "private_endpoint_name" {
  type        = string
  description = "(Optional) The name of the private endpoint. If not specified, a name will be generated."
  default     = null
}

variable "private_endpoint_approval_required" {
  type        = bool
  description = "(Optional) Whether manual approval is required for private endpoint connections. Default is false."
  default     = false
}

variable "action_group_enabled" {
  type        = bool
  description = "(Optional) Whether to create action group and alerts for this Redis cache. Default is false."
  default     = false
}

variable "action_group_name" {
  type        = string
  description = "(Optional) The name of the action group for alerts. If not specified, one will be generated."
  default     = null
}

variable "alert_email_receivers" {
  type        = list(string)
  description = "(Optional) List of email addresses to receive alerts."
  default     = []
}

variable "alert_high_cpu_threshold" {
  type        = number
  description = "(Optional) CPU usage percentage threshold for alerting. Default is 80."
  default     = 80

  validation {
    condition     = var.alert_high_cpu_threshold >= 0 && var.alert_high_cpu_threshold <= 100
    error_message = "alert_high_cpu_threshold must be between 0 and 100."
  }
}

variable "alert_high_memory_threshold" {
  type        = number
  description = "(Optional) Memory usage percentage threshold for alerting. Default is 80."
  default     = 80

  validation {
    condition     = var.alert_high_memory_threshold >= 0 && var.alert_high_memory_threshold <= 100
    error_message = "alert_high_memory_threshold must be between 0 and 100."
  }
}

variable "alert_eviction_threshold" {
  type        = number
  description = "(Optional) Number of evictions per minute threshold for alerting. Default is 100."
  default     = 100
}

variable "alert_connection_failures_threshold" {
  type        = number
  description = "(Optional) Number of connection failures threshold for alerting. Default is 10."
  default     = 10
}

