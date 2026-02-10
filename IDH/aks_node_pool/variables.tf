variable "product_name" {
  type        = string
  description = "(Required): Product name used to identify the platform for which the resource will be created."
}

variable "env" {
  type        = string
  description = "(Required): Environment for which the resource will be created."
}

variable "idh_resource_tier" {
  type        = string
  description = "(Required): The name of IDH resource tier to be created."
}

variable "name" {
  type        = string
  description = "(Required): Node pool name. Must not exceed 12 characters."
  validation {
    condition     = length(var.name) <= 12
    error_message = "The node pool name must not exceed 12 characters."
  }
}

variable "kubernetes_cluster_id" {
  type        = string
  description = "(Required): AKS cluster id."
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Optional): Subnet id for the node pool."
  default     = null
}

variable "embedded_subnet" {
  type = object({
    enabled      = bool
    vnet_name    = optional(string, null)
    vnet_rg_name = optional(string, null)
    subnet_name  = optional(string, null)
    natgw_id     = optional(string, null)
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the AKS Nodepool. If 'enabled' is true, 'vnet_subnet_id' must be null"
  default = {
    enabled      = false
    vnet_name    = null
    vnet_rg_name = null
    subnet_name  = null
    natgw_id     = null
  }


  validation {
    condition     = var.embedded_subnet.enabled ? var.vnet_subnet_id == null : true
    error_message = "If 'embedded_subnet' is enabled, 'vnet_subnet_id' must be null."
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

variable "create_self_inbound_nsg_rule" {
  type        = bool
  description = "(Optional) Flag the automatic creation of self-inbound security rules. Set to true to allow internal traffic within the same security scope"
  default     = true
}

variable "autoscale_enabled" {
  default     = true
  type        = bool
  description = "(Optional): Enable autoscaling for the node pool. Defaults to true."
}

variable "node_count_min" {
  type        = number
  description = "(Required): Minimum number of nodes in the node pool."
  validation {
    condition     = var.node_count_min >= module.idh_loader.idh_resource_configuration.node_min_allowed ? true : false
    error_message = "The node count minimum: ${var.node_count_min} must be greater than or equal to the allowed minimum: ${module.idh_loader.idh_resource_configuration.node_min_allowed} nodes for the resource tier."
  }
}

variable "node_count_max" {
  type        = number
  description = "(Required): Maximum number of nodes in the node pool."
}

variable "node_labels" {
  type        = map(string)
  description = "(Required): Map of labels to assign to the nodes."
}

variable "node_taints" {
  type        = list(string)
  default     = [""]
  description = "(Optional): List of taints to assign to the nodes."
}

variable "node_tags" {
  type        = map(any)
  description = "(Required): Map of tags to assign to the nodes."
}

variable "os_disk_type" {
  type        = string
  description = "(Optional): Type of OS disk"
  default     = null
}

variable "os_disk_size_gb" {
  type        = number
  description = "(Optional): OS disk size in GB"
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "(Optional): Map of tags to assign to the resource."
}
