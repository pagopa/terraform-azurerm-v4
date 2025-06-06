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
  description = "(Required) The name which should be used for this PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where the PostgreSQL Flexible Server should exist."
}


variable "idh_resource" {
  type        = string
  description = "(Required) The name od IDH resource key to be created."
}


variable "virtual_network_name" {
  type = string
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
