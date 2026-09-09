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


variable "tags" {
  type        = map(any)
  description = "(Optional): Map of tags to assign to the resource."
}

variable "vmss_resource_group_name" {
  type        = string
  description = "(Required): The name of the resource group in which to create the VMSS resource."
}


variable "name" {
  type        = string
  description = "(Required): The name (prefix) for the created resources"
}

variable "vnet" {
  type = object({
    name                = string
    resource_group_name = string
  })
  description = "(Required): The name and resource group of the virtual network to which the VMSS subnet will be attached."
}

variable "nat_gateway" {
  type = object({
    name                = string
    resource_group_name = string
  })
  description = "(Optional): The name and resource group of the NAT gateway to be associated with the VMSS subnet. If not defined, no NAT gateway will be associated with the subnet."
  default = null
}


variable "vmss_credentials" {
  type = object({
    admin_login    = string
    admin_password = string
  })
  description = "(Required): The administrator login and password for the VMSS instances."
  sensitive = true
}


variable "database_adf_proxy_mapping" {
  type = list(object({
    fqdn             = string
    external_port    = number
    destination_port = number
  }))
  description = "(Required): List of database ADF proxy mappings."

  validation {
    # Validate that the list does not contain duplicate FQDNs
    condition = length(var.database_adf_proxy_mapping) == length(distinct([for db in var.database_adf_proxy_mapping : db.fqdn]))
    error_message = "Duplicate FQDNs found in database_adf_proxy_mapping. Each FQDN must be unique."
  }

  validation {
    # Validate that the list does not contain duplicate external ports
    condition = length(var.database_adf_proxy_mapping) == length(distinct([for db in var.database_adf_proxy_mapping : db.external_port]))
    error_message = "Duplicate external ports found in database_adf_proxy_mapping. Each external port must be unique."
  }
}
