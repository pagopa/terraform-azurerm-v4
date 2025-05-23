#########################################
# General Variables
#########################################

variable "prefix" {
  type = string
  validation {
    condition     = length(var.prefix) > 0 && length(var.prefix) <= 6 && can(regex("^[a-zA-Z0-9]+$", var.prefix))
    error_message = "The prefix must be 1 to 6 alphanumeric characters."
  }
}

variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.env)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+[a-z0-9]$", var.location))
    error_message = "Location must comply with Azure region format (e.g., 'westeurope')."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the CosmosDB Account is created. Changing this forces a new resource to be created."
  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource Group name cannot be empty."
  }
}

variable "tags" {
  type = map(any)
  validation {
    condition     = length(keys(var.tags)) >= 0
    error_message = "Tags must be a map, even if empty."
  }
}

#########################################
# IDH Resources
#########################################

variable "idh_resource" {
  type        = string
  description = "(Required) The name of IDH resource key to be created."
  validation {
    condition     = length(var.idh_resource) > 0
    error_message = "IDH resource key name cannot be empty."
  }
}

#########################################
# CosmosDB Account Settings
#########################################

variable "name" {
  type        = string
  description = "(Required) Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created."
  validation {
    condition     = length(var.name) > 0 && can(regex("^[a-z0-9-]+$", var.name))
    error_message = "CosmosDB name must be lowercase and can only contain letters, numbers, and hyphens."
  }
}

variable "domain" {
  type        = string
  description = "(Optional) Specifies the domain of the CosmosDB Account."
  validation {
    condition     = var.domain == null || can(regex("^[a-zA-Z0-9.-]*$", var.domain))
    error_message = "Domain can contain only letters, numbers, dots and hyphens."
  }
}

variable "enable_automatic_failover" {
  type        = bool
  default     = true
  description = "Enable automatic fail over for this Cosmos DB account."
  validation {
    condition     = var.enable_automatic_failover == true || var.enable_automatic_failover == false
    error_message = "Enable automatic failover must be a boolean value."
  }
}

#########################################
# Geo-replication
#########################################

variable "main_geo_location_location" {
  type        = string
  description = "(Required) The name of the Azure region to host replicated data."
  validation {
    condition     = length(var.main_geo_location_location) > 0
    error_message = "Main geo location cannot be empty."
  }
}

variable "additional_geo_locations" {
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = bool
  }))
  default     = []
  description = "Specifies a list of additional geo_location resources, used to define where data should be replicated."
  validation {
    condition     = var.additional_geo_locations != null
    error_message = "Additional geo locations must be a list, even if empty."
  }
  validation {
    condition     = !module.idh_loader.idh_config.additional_geo_replication_allowed ? length(var.additional_geo_locations) == 0 : true
    error_message = "Additional geo replication is not allowed in '${var.env}' environment for '${var.idh_resource}'"
  }
}

#########################################
# Security and Networking Settings
#########################################

variable "key_vault_key_id" {
  type        = string
  description = "(Optional) A versionless Key Vault Key ID for CMK encryption. Changing this forces a new resource to be created. When referencing an azurerm_key_vault_key resource, use versionless_id instead of id"
  default     = null
  validation {
    condition     = var.key_vault_key_id == null || can(regex("^https://[a-zA-Z0-9-]+\\.vault.azure.net/keys/[a-zA-Z0-9-]+$", var.key_vault_key_id))
    error_message = "key_vault_key_id must be a valid Azure Key Vault Key URI or null."
  }
}

variable "allowed_virtual_network_subnet_ids" {
  type        = list(string)
  description = "The subnets id that are allowed to access this CosmosDB account."
  default     = []
  validation {
    condition     = var.allowed_virtual_network_subnet_ids != null
    error_message = "Allowed virtual network subnet ids must be a list, even if empty."
  }
}

variable "ip_range" {
  type        = list(string)
  description = "The set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IP's for a given database account."
  default     = null
  validation {
    condition     = var.ip_range == null ? true : alltrue([for ip in var.ip_range : can(cidrhost(ip, 0))])
    error_message = "All IPs in ip_range, if provided, must be in valid CIDR notation."
  }
}

variable "subnet_id" {
  type        = string
  description = "Used only for private endpoints"
  default     = null
  validation {
    condition     = var.subnet_id == null || can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", var.subnet_id))
    error_message = "subnet_id must be a valid Azure subnet resource ID or null."
  }
}

#########################################
# Private Endpoint Configuration
#########################################

variable "private_endpoint_config" {
  description = "Configuration for private endpoint and DNS zones for CosmosDB"
  type = object({
    subnet_id                         = string
    private_dns_zone_sql_ids          = list(string)
    private_dns_zone_table_ids        = list(string)
    private_dns_zone_mongo_ids        = list(string)
    private_dns_zone_cassandra_ids    = list(string)
    enabled                           = bool
    name_sql                          = string
    service_connection_name_sql       = string
    name_mongo                        = string
    service_connection_name_mongo     = string
    name_cassandra                    = string
    service_connection_name_cassandra = string
    name_table                        = string
  })
  default = {
    subnet_id                         = null
    private_dns_zone_sql_ids          = []
    private_dns_zone_table_ids        = []
    private_dns_zone_mongo_ids        = []
    private_dns_zone_cassandra_ids    = []
    enabled                           = true
    name_sql                          = null
    service_connection_name_sql       = null
    name_mongo                        = null
    service_connection_name_mongo     = null
    name_cassandra                    = null
    service_connection_name_cassandra = null
    name_table                        = null
  }
  validation {
    condition = (
      (var.private_endpoint_config.subnet_id == null || can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", var.private_endpoint_config.subnet_id))) &&
      var.private_endpoint_config.private_dns_zone_sql_ids != null &&
      var.private_endpoint_config.private_dns_zone_table_ids != null &&
      var.private_endpoint_config.private_dns_zone_mongo_ids != null &&
      var.private_endpoint_config.private_dns_zone_cassandra_ids != null &&
      (var.private_endpoint_config.enabled == true || var.private_endpoint_config.enabled == false)
    )
    error_message = "private_endpoint_config subnet_id must be null or a valid Azure subnet resource ID; all private_dns_zone_* fields must be lists; enabled must be boolean."
  }
}
