variable "product_name" {
  type        = string
  description = "(Required) Product/platform identifier for which the resource will be created."
  nullable    = false

  validation {
    condition     = length(var.product_name) <= 6
    error_message = "product_name max length is 6 characters."
  }
}

variable "env" {
  type        = string
  description = "(Required) Environment for which the resource will be created (dev, test, uat, prod)."
  nullable    = false
}

variable "idh_resource_tier" {
  type        = string
  description = "(Required) The IDH resource tier name from YAML config (e.g., 'basic', 'standard', 'premium')."
  nullable    = false
}

variable "location" {
  type        = string
  description = "(Required) Azure region where the Redis Cache will be created."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) Resource group name where to create the Redis Cache."
  nullable    = false
}

variable "tags" {
  type        = map(any)
  description = "(Required) Tags to apply to all created resources."
  nullable    = false
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "(Optional) Enable private endpoint for secure VNet connectivity."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "(Optional) Subnet ID where the private endpoint will be created."
  default     = null
}

variable "private_endpoint_name" {
  type        = string
  description = "(Optional) Custom name for the private endpoint."
  default     = null
}

variable "action_group_enabled" {
  type        = bool
  description = "(Optional) Enable alert action group for notifications."
  default     = false
}

variable "alert_email_receivers" {
  type        = list(string)
  description = "(Optional) Email addresses for alert notifications."
  default     = []
}

variable "alert_high_cpu_threshold" {
  type        = number
  description = "(Optional) CPU percentage threshold for high CPU alert."
  default     = 80
}

variable "alert_high_memory_threshold" {
  type        = number
  description = "(Optional) Memory percentage threshold for high memory alert."
  default     = 80
}

variable "alert_eviction_threshold" {
  type        = number
  description = "(Optional) Evictions per second threshold for eviction alert."
  default     = 100
}

variable "alert_connection_failures_threshold" {
  type        = number
  description = "(Optional) Connection failures per minute threshold."
  default     = 10
}
