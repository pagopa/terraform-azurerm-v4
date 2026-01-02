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
  description = "(Deprecated) Enable private endpoint with required params. Use 'embedded_subnet' instead."
  default     = null

  validation {
    condition     = module.idh_loader.idh_resource_configuration.private_endpoint_enabled && !var.embedded_subnet.enabled? var.private_endpoint != null : true
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
    condition     = var.capacity == null || contains([0, 1, 2, 3, 4, 5, 6], coalesce(var.capacity, -1))
    error_message = "The capacity value must be one of: 0, 1, 2, 3, 4, 5, 6"
  }
}


variable "embedded_subnet" {
  type = object({
    enabled              = bool
    vnet_name            = optional(string, null)
    vnet_rg_name         = optional(string, null)
    private_dns_zone_ids = optional(list(string), []) #dns zone for private endpoint
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the Redis private endpoint. When enabled, 'private_endpoint.subnet_id' must be null."
  default = {
    enabled              = false
    vnet_name            = null
    vnet_rg_name         = null
    private_dns_zone_ids = []
  }


  validation {
    condition     = var.embedded_subnet.enabled ? var.private_endpoint == null : true
    error_message = "If 'embedded_subnet' is enabled, 'private_endpoint' must be null."
  }

  validation {
    condition     = var.embedded_subnet.enabled ? (var.embedded_subnet.vnet_name != null && var.embedded_subnet.vnet_rg_name != null) : true
    error_message = "If 'embedded_subnet' is enabled, both 'vnet_name' and 'vnet_rg_name' must be provided."
  }

  validation {
    condition     = var.embedded_subnet.enabled && module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? length(var.embedded_subnet.private_dns_zone_ids) > 0 : true
    error_message = "If 'embedded_subnet' is enabled and private endpoint is enabled, 'private_dns_zone_ids' must contain at least one DNS zone ID."
  }


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
    source_address_prefixes_name = string # short name for source_address_prefixes
  })
  description = "(Optional) List of allowed cidr and name . Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration"
  default = {
    source_address_prefixes : ["*"]
    source_address_prefixes_name = "All"
  }
}
