variable "product_name" {
  type = string
  validation {
    condition = (
      length(var.product_name) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type = string
}

variable "name" {
  type        = string
  description = "(Required) Name of the subnet to be created"
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where the subnet should exist."
}


variable "idh_resource_tier" {
  type        = string
  description = "(Required) The name od IDH resource key to be created."
}


variable "virtual_network_name" {
  type        = string
  description = "(Required) Name of the virtual network where the subnet will be created."
}

variable "service_endpoints" {
  type        = list(string)
  default     = []
  description = "(Optional) The list of Service endpoints to associate with the subnet. Possible values include: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB, Microsoft.ContainerRegistry, Microsoft.EventHub, Microsoft.KeyVault, Microsoft.ServiceBus, Microsoft.Sql, Microsoft.Storage and Microsoft.Web."
}

variable "private_endpoint_network_policies" {
  type        = string
  description = "(Optional) Enable or Disable network policies for the private endpoint on the subnet. Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled. Defaults to Disabled."
  default     = "Disabled"
}

variable "embedded_nsg_configuration" {
  type = object({
    source_address_prefixes      = list(string)
    source_address_prefixes_name = string # short name for source_address_prefixes
  })
  description = "(Optional) List of allowed cidr and name. Available only if the subnet tier supports embedded nsg Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration"
  default = {
    source_address_prefixes : ["*"]
    source_address_prefixes_name = "All"
  }

  validation {
    condition     = can(module.idh_loader.idh_resource_configuration.nsg) ? var.embedded_nsg_configuration != null : true
    error_message = "'embedded_nsg' not available for subnet tier ${var.idh_resource_tier}. use custom_nsg_configuration instead."
  }
}

variable "custom_nsg_configuration" {
  type = object({
    source_address_prefixes      = list(string)
    source_address_prefixes_name = string # short name for source_address_prefixes
    target_ports                 = optional(list(string), null)
    protocol                     = optional(string, null)
    target_service               = optional(string, null)
  })
  description = "(Optional) Custom NSG configuration, additional to eventually present embedded nsg"
  default     = null

  validation {
    condition = var.custom_nsg_configuration != null && try(var.custom_nsg_configuration.target_service, null) != null ? (var.custom_nsg_configuration.target_ports == null && var.custom_nsg_configuration.protocol == null) : true
    error_message = "If target_service is defined,  (target_ports, protocol) must be null"
  }

  validation {
     condition = var.custom_nsg_configuration != null && try(var.custom_nsg_configuration.target_service, null) == null ? (var.custom_nsg_configuration.target_ports != null && var.custom_nsg_configuration.protocol != null) : true
    error_message = "If target_service is NOT defined,  (target_ports, protocol) must be defined"
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

  validation {
    condition     = var.nsg_flow_log_configuration.enabled ? var.nsg_flow_log_configuration.network_watcher_name != null && try(var.nsg_flow_log_configuration.network_watcher_name, "") != "" : true
    error_message = "'nsg_flow_log_configuration.network_watcher_name' must not be null or empty when 'nsg_flow_log_configuration.enabled' is 'true'"
  }

  validation {
    condition     = var.nsg_flow_log_configuration.enabled ? var.nsg_flow_log_configuration.network_watcher_rg != null && try(var.nsg_flow_log_configuration.network_watcher_rg, "") != "" : true
    error_message = "'nsg_flow_log_configuration.network_watcher_rg' must not be null or empty when 'nsg_flow_log_configuration.enabled' is 'true'"
  }

  validation {
    condition     = var.nsg_flow_log_configuration.enabled ? var.nsg_flow_log_configuration.storage_account_id != null && try(var.nsg_flow_log_configuration.storage_account_id, "") != "" : true
    error_message = "'nsg_flow_log_configuration.storage_account_id' must not be null or empty when 'nsg_flow_log_configuration.enabled' is 'true'"
  }

  validation {
    condition     = var.nsg_flow_log_configuration.enabled ? var.nsg_flow_log_configuration.traffic_analytics_law_name != null && try(var.nsg_flow_log_configuration.traffic_analytics_law_name, "") != "" : true
    error_message = "'nsg_flow_log_configuration.traffic_analytics_law_name' must not be null or empty when 'nsg_flow_log_configuration.enabled' is 'true'"
  }

  validation {
    condition     = var.nsg_flow_log_configuration.enabled ? var.nsg_flow_log_configuration.traffic_analytics_law_rg != null && try(var.nsg_flow_log_configuration.traffic_analytics_law_rg, "") != "" : true
    error_message = "'nsg_flow_log_configuration.traffic_analytics_law_rg' must not be null or empty when 'nsg_flow_log_configuration.enabled' is 'true'"
  }
}

variable "tags" {
  type        = map(any)
  description = "Map of tags added to the resources created by this module"
}
