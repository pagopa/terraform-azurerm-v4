variable "product_name" {
  type        = string
  description = "(Required) prefix used to identify the platform for which the resource will be created"
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
  description = "(Required) The name of IDH resource key to be created."
}

variable "name" {
  type        = string
  description = "Eventhub namespace description."
}

variable "location" {
  type = string
}

// Resource Group
variable "resource_group_name" {
  type = string
}


variable "eventhubs" {
  description = "A list of event hubs to add to namespace."
  type = list(object({
    name              = string       # (Required) Specifies the name of the EventHub resource. Changing this forces a new resource to be created.
    partitions        = number       # (Required) Specifies the current number of shards on the Event Hub.
    message_retention = number       # (Required) Specifies the number of days to retain the events for this Event Hub.
    consumers         = list(string) # Manages a Event Hubs Consumer Group as a nested resource within an Event Hub.
    keys = list(object({
      name   = string # (Required) Specifies the name of the EventHub Authorization Rule resource. Changing this forces a new resource to be created.
      listen = bool   # (Optional) Does this Authorization Rule have permissions to Listen to the Event Hub? Defaults to false.
      send   = bool   # (Optional) Does this Authorization Rule have permissions to Send to the Event Hub? Defaults to false.
      manage = bool   # (Optional) Does this Authorization Rule have permissions to Manage to the Event Hub? When this property is true - both listen and send must be too. Defaults to false.
    }))               # Manages a Event Hubs authorization Rule within an Event Hub.
  }))
  default = []
}




variable "network_rulesets" {
  type = list(object({
    default_action                = string                #  (Required) The default action to take when a rule is not matched. Possible values are Allow and Deny.
    public_network_access_enabled = optional(bool, false) # (Optional) Is public network access enabled for the EventHub Namespace? Defaults to false.
    virtual_network_rule = list(object({
      subnet_id                                       = string # (Required) The id of the subnet to match on.
      ignore_missing_virtual_network_service_endpoint = bool   # (Optional) Are missing virtual network service endpoints ignored?
    }))
    ip_rule = list(object({
      ip_mask = string # (Required) The IP mask to match on.
      action  = string # (Optional) The action to take when the rule is matched. Possible values are Allow. Defaults to Allow.
    }))
    trusted_service_access_enabled = optional(bool, false) #Whether Trusted Microsoft Services are allowed to bypass firewall.
  }))
  default = []
}


#
# Private endpoint
#

variable "private_dns_zones_ids" {
  description = "Private DNS Zones where the private endpoint will be created"
  type        = list(string)
  default     = []
}


variable "private_endpoint_resource_group_name" {
  description = "Name of the resource group where the private endpoint will be created"
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "(Deprecated) The id of the subnet that will be used for the private endpoint. Use embedded_subnet instead."
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


variable "tags" {
  type = map(any)
}

#
# Alerts
#

variable "metric_alerts" {
  default = {}

  description = <<EOD
Map of name = criteria objects
EOD

  type = map(object({
    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]
    aggregation = string
    metric_name = string
    description = string
    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]
    operator  = string
    threshold = number
    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H
    frequency = string
    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.
    window_size = string

    dimension = list(object(
      {
        name     = string
        operator = string
        values   = list(string)
      }
    ))
  }))
}


variable "embedded_subnet" {
  type = object({
    enabled      = bool
    vnet_name    = optional(string, null)
    vnet_rg_name = optional(string, null)
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the EventHub private endpoint. When enabled, 'private_endpoint.subnet_id' must be null."
  default = {
    enabled      = false
    vnet_name    = null
    vnet_rg_name = null
  }


  validation {
    condition     = var.embedded_subnet.enabled ? var.private_endpoint_subnet_id == null : true
    error_message = "If 'embedded_subnet' is enabled, 'private_endpoint_subnet_id' must be null."
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
    source_address_prefixes_name = string # short name for source_address_prefixes
  })
  description = "(Optional) List of allowed cidr and name . Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration"
  default = {
    source_address_prefixes : ["*"]
    source_address_prefixes_name = "All"
  }
}
