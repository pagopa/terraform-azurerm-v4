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
  description = "The location of the resource group."
}

variable "name" {
  type        = string
  description = "The name of the Redis instance."
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "The Subnet within which the Redis Cache should be deployed (Deprecated, use private_endpoint)"
  default     = null

  validation {
    condition     = !module.idh_loader.idh_resource_configuration.subnet_integration ? var.subnet_id == null : true
    error_message = "subnet_integration is disabled for resource '${var.idh_resource_tier}' on env '${var.env}'. This variable must be null"
  }
}

variable "private_endpoint" {
  type = object({
    subnet_id            = string
    private_dns_zone_ids = list(string)
  })
  description = "(Optional) Enable private endpoint with required params"
  default     = null

  validation {
    condition     = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? var.private_endpoint != null : true
    error_message = "private_endpoint must be defined for resource '${var.idh_resource_tier}' on env '${var.env}'"
  }

  validation {
    condition     = var.private_endpoint != null ? var.private_endpoint.subnet_id != null && length(var.private_endpoint.private_dns_zone_ids) > 0 : true
    error_message = "use valid subnet_id and private_dns_zone_ids when defining the private endpoint"
  }
}

variable "private_static_ip_address" {
  type        = string
  description = "The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network"
  default     = null

  validation {
    condition     = !module.idh_loader.idh_resource_configuration.subnet_integration ? var.private_static_ip_address == null : true
    error_message = "subnet_integration is disabled for resource '${var.idh_resource_tier}' on env '${var.env}'. This variable must be null"
  }
}


variable "tags" {
  type = map(any)
}

variable "alert_action_group_ids" {
  type        = list(string)
  default     = []
  description = "(Optional) List of action group ids to be used in alerts"
}

variable "patch_schedules" {
  type = list(object({
    day_of_week    = string
    start_hour_utc = number
  }))
  default     = null
  description = "(Optional) List of day-time where Azure can start the maintenance activity"
}

variable "capacity" {
  type        = number
  default     = null
  description = "(Required) The size of the Redis cache to deploy. Valid values are 0, 1, 2, 3, 4, 5 and 6 for Basic/Standard SKU and 1, 2, 3, 4 for Premium SKU."
  validation {
    condition     = var.capacity == null || (var.capacity != null && contains([0, 1, 2, 3, 4, 5, 6], var.capacity))
    error_message = "The capacity value must be one of: 0, 1, 2, 3, 4, 5, 6"
  }
}
