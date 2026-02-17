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

variable "tags" {
  type        = map(any)
  description = "(Required) A mapping of tags which should be assigned to the Resource."
}

variable "log_analytics_workspace_tables" {
  type = map(object({
    retention_in_days       = optional(number)
    total_retention_in_days = optional(number)
  }))
  description = "A map of tables to create in the Log Analytics Workspace"
  default     = {}
}

variable "create_application_insights" {
  type        = bool
  description = "Should the Application Insights be created?"
  default     = true
  validation {
    condition = (
      var.create_application_insights && var.application_insights_id != null ? false : true
    )
    error_message = "If 'create_application_insights' is true, 'application_insights_id' must be null. If 'application_insights_id' is provided, 'create_application_insights' must be false."
  }
}

variable "application_insights_name" {
  type        = string
  description = "The name of the Application Insights. If creating, and not provided, it will be generated from the workspace name. If obtaining existing, this is required."
  default     = null
  validation {
    condition = (
      var.application_insights_id != null && var.application_insights_name == null ? false : true
    )
    error_message = "If 'application_insights_id' is provided (obtaining an existing resource), 'application_insights_name' is required."
  }
}

variable "application_insights_id" {
  type        = string
  description = "The ID of an existing Application Insights resource. If provided, no new Application Insights will be created."
  default     = null
}

variable "application_insights_resource_group_name" {
  type        = string
  description = "The Resource Group name of the existing Application Insights. If not provided, the workspace resource group will be used."
  default     = null
}

variable "embedded_subnet" {
  type = object({
    enabled      = bool
    vnet_name    = optional(string, null)
    vnet_rg_name = optional(string, null)
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the Log Analytics Workspace. If 'enabled' is true, 'subnet_id' must be null"
  default = {
    enabled      = false
    vnet_name    = null
    vnet_rg_name = null
  }

  validation {
    condition     = var.embedded_subnet.enabled ? (var.embedded_subnet.vnet_name != null && var.embedded_subnet.vnet_rg_name != null) : true
    error_message = "If 'embedded_subnet' is enabled, both 'vnet_name' and 'vnet_rg_name' must be provided."
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
    source_address_prefixes_name = string ## short name for source_address_prefixes
  })
  description = "(Optional) List of allowed cidr and name . Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration"
  default = {
    source_address_prefixes : ["*"]
    source_address_prefixes_name = "All"
  }
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "A list of Private DNS Zone IDs for the Private Endpoint."
  default     = []
}