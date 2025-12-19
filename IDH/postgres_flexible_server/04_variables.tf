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

variable "name" {
  type        = string
  description = "(Required) The name which should be used for this PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
}

variable "location" {
  type        = string
  description = "(Required) The Azure Region where the PostgreSQL Flexible Server should exist."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where the PostgreSQL Flexible Server should exist."
}


variable "idh_resource_tier" {
  type        = string
  description = "(Required) The name od IDH resource key to be created."
}

#
# Network
#


variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the private dns zone to create the PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
}

variable "delegated_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the virtual network subnet to create the PostgreSQL Flexible Server. The provided subnet should not have any other resource deployed in it and this subnet will be delegated to the PostgreSQL Flexible Server, if not already delegated."
}



#
# Administration
#


variable "customer_managed_key_enabled" {
  type        = bool
  description = "enable customer_managed_key"
  default     = false
}

variable "customer_managed_key_kv_key_id" {
  type        = string
  description = "The ID of the Key Vault Key"
  default     = null
}

variable "administrator_login" {
  type        = string
  description = "Flexible PostgreSql server administrator_login"
}

variable "administrator_password" {
  type        = string
  description = "Flexible PostgreSql server administrator_password"
}

variable "db_version" {
  type        = string
  description = "(Optional) PostgreSQL version"
  default     = null
}

variable "storage_mb" {
  type        = number
  description = "(Optional) The size of the storage in MB. Changing this forces a new PostgreSQL Flexible Server to be created."
  default     = null
}

variable "storage_tier" {
  type        = string
  description = "(Optional) The storage tier of the PostgreSQL Flexible Server. Possible values are P4, P6, P10, P15,P20, P30,P40, P50,P60, P70 or P80. Default value is dependant on the storage_mb value. "
  default     = null
}

variable "primary_user_assigned_identity_id" {
  type        = string
  description = "Manages a User Assigned Identity"
  default     = null
}

#
# Monitoring & Alert
#
variable "custom_metric_alerts" {
  default = null

  description = <<EOD
  Map of name = criteria objects
  EOD

  type = map(object({
    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]
    aggregation = string
    metric_name = string
    # "Insights.Container/pods" "Insights.Container/nodes"
    metric_namespace = string
    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]
    operator  = string
    threshold = number
    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H
    frequency = string
    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.
    window_size = string
    # severity: The severity of this Metric Alert. Possible values are 0, 1, 2, 3 and 4. Defaults to 3.
    severity = number
  }))
}


variable "alert_action" {
  description = "The ID of the Action Group and optional map of custom string properties to include with the post webhook operation."
  type = set(object(
    {
      action_group_id    = string
      webhook_properties = map(string)
    }
  ))
  default = []
}

variable "diagnostic_settings_enabled" {
  type        = bool
  default     = true
  description = "Is diagnostic settings enabled?"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent."
}

variable "diagnostic_setting_destination_storage_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Storage Account where logs should be sent. Changing this forces a new resource to be created."
}

variable "tags" {
  type = map(any)
}

variable "private_dns_registration" {
  type        = bool
  default     = false
  description = "(Optional) If true, creates a cname record for the newly created postgreSQL db fqdn into the provided private dns zone"

  validation {
    condition     = var.private_dns_registration ? !(module.idh_loader.idh_resource_configuration.geo_replication_allowed && var.geo_replication.enabled && var.geo_replication.private_dns_registration_ve) : true
    error_message = "private_dns_registration must be false if geo_replication.private_dns_registration_ve is true"
  }
}

variable "private_dns_zone_name" {
  type        = string
  default     = null
  description = "(Optional) if 'private_dns_registration' is true, defines the private dns zone name in which the server fqdn should be registered"

  validation {
    condition     = var.private_dns_registration ? var.private_dns_zone_name != null : true
    error_message = "private_dns_zone_name must be defined when private_dns_registration is true"
  }
}

variable "private_dns_zone_rg_name" {
  type        = string
  default     = null
  description = "(Optional) if 'private_dns_registration' is true, defines the private dns zone resource group name of the dns zone in which the server fqdn should be registered"

  validation {
    condition     = var.private_dns_registration ? var.private_dns_zone_rg_name != null : true
    error_message = "private_dns_zone_rg_name must be defined when private_dns_registration is true"
  }
}

variable "private_dns_record_cname" {
  type        = string
  default     = null
  description = "(Optional) if 'private_dns_registration' is true, defines the private dns CNAME used to register this server FQDN"

  validation {
    condition     = var.private_dns_registration ? var.private_dns_record_cname != null : true
    error_message = "private_dns_record_cname must be defined when private_dns_registration is true"
  }
}

variable "private_dns_cname_record_ttl" {
  type        = number
  default     = 300
  description = "(Optional) if 'private_dns_registration' is true, defines the record TTL"
}

variable "auto_grow_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is the storage auto grow for PostgreSQL Flexible Server enabled? Defaults to false"
}

variable "databases" {
  type        = list(string)
  description = "(Optional) List of database names to be created"
  default     = []
}

variable "geo_replication" {
  type = object({
    enabled                     = bool
    name                        = optional(string, null)
    subnet_id                   = optional(string, null)
    location                    = optional(string, null)
    private_dns_registration_ve = optional(bool, false)
  })
  default = {
    enabled                     = false
    name                        = null
    subnet_id                   = null
    location                    = null
    private_dns_registration_ve = false
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

variable "pg_bouncer_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Enable or disable PgBouncer. Defaults to false (Server will be restarted on change!)"
}

variable "zone" {
  type        = number
  default     = null
  description = "(Optional) The Availability Zone in which the PostgreSQL Flexible Server should be located. (1,2,3)"
}

variable "additional_azure_extensions" {
  type        = list(string)
  default     = []
  description = "(Optional) List of additional azure extensions to be installed on the server"
  validation {
    condition     = alltrue([for ext in var.additional_azure_extensions : !contains(split(",", module.idh_loader.idh_resource_configuration.server_parameters.azure_extensions), ext)])
    error_message = "At least one of the additional_azure_extensions is already included in the preconfigured extensions: ${module.idh_loader.idh_resource_configuration.server_parameters.azure_extensions}"
  }
}


variable "embedded_subnet" {
  type = object({
    enabled              = bool
    vnet_name            = optional(string, null)
    vnet_rg_name         = optional(string, null)
    replica_vnet_name    = optional(string, null)
    replica_vnet_rg_name = optional(string, null)
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the PostgreSQL Flexible Server. If 'enabled' is true, 'delegated_subnet_id' must be null"
  default = {
    enabled              = false
    vnet_name            = null
    vnet_rg_name         = null
    replica_vnet_name    = null
    replica_vnet_rg_name = null
  }


  validation {
    condition     = var.embedded_subnet.enabled ? var.delegated_subnet_id == null : true
    error_message = "If 'embedded_subnet' is enabled, 'delegated_subnet_id' must be null."
  }

  validation {
    condition     = var.embedded_subnet.enabled ? (var.embedded_subnet.vnet_name != null && var.embedded_subnet.vnet_rg_name != null) : true
    error_message = "If 'embedded_subnet' is enabled, both 'vnet_name' and 'vnet_rg_name' must be provided."
  }

  validation {
    error_message = "If 'embedded_subnet' is enabled and geo_replication is enabled, both 'embedded_subnet.replica_vnet_name' and 'embedded_subnet.replica_vnet_rg_name' must be provided."
    condition     = (var.embedded_subnet.enabled && var.geo_replication.enabled) ? (var.embedded_subnet.replica_vnet_name != null && var.embedded_subnet.replica_vnet_rg_name != null) : true
  }

  validation {
    error_message = "If 'embedded_subnet' is enabled and geo_replication is enabled, geo_replication.subnet_id must be null."
    condition     = (var.embedded_subnet.enabled && var.geo_replication.enabled) ? var.geo_replication.subnet_id == null : true
  }

  validation {
    error_message = "If geo_replication is enabled and embedded_subnet is disabled, 'subnet_id' must be provided"
    condition     = var.geo_replication.enabled ? (var.embedded_subnet.enabled ? true : var.geo_replication.subnet_id != null) : true
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
