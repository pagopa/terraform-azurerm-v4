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

variable "offer_type" {
  type        = string
  description = "The CosmosDB account offer type. Currently can only be set to 'Standard'."
  default     = "Standard"
  validation {
    condition     = var.offer_type == "Standard"
    error_message = "The only valid value for 'offer_type' is 'Standard'."
  }
}

variable "enable_free_tier" {
  type        = bool
  default     = false
  description = "Enable Free Tier pricing option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be created."
  validation {
    condition     = var.enable_free_tier == true || var.enable_free_tier == false
    error_message = "Enable Free Tier must be a boolean value."
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

variable "burst_capacity_enabled" {
  type        = bool
  description = "(Optional) Enable burst capacity for this Cosmos DB account. Defaults to false."
  default     = false
  validation {
    condition     = var.burst_capacity_enabled == true || var.burst_capacity_enabled == false
    error_message = "Burst capacity enabled must be a boolean value."
  }
}

#########################################
# Consistency, Capabilities and Backup
#########################################

variable "consistency_policy" {
  type = object({
    consistency_level       = string
    max_interval_in_seconds = number
    max_staleness_prefix    = number
  })
  default = {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }
  description = "Specifies a consistency_policy resource, used to define the consistency policy for this CosmosDB account."
  validation {
    condition     = contains(["BoundedStaleness", "Strong", "Session", "Eventual", "ConsistentPrefix"], var.consistency_policy.consistency_level)
    error_message = "Consistency level must be one of: BoundedStaleness, Strong, Session, Eventual, ConsistentPrefix."
  }
}

variable "capabilities" {
  type        = list(string)
  description = "The capabilities which should be enabled for this Cosmos DB account."
  default     = []
  validation {
    condition     = var.capabilities != null
    error_message = "Capabilities must be a list, even if empty."
  }
}


variable "enable_provisioned_throughput_exceeded_alert" {
  type        = bool
  description = "Enable the Provisioned Throughput Exceeded alert. Default is true"
  default     = true
  validation {
    condition     = var.enable_provisioned_throughput_exceeded_alert == true || var.enable_provisioned_throughput_exceeded_alert == false
    error_message = "Enable provisioned throughput exceeded alert must be a boolean value."
  }
}

variable "provisioned_throughput_exceeded_threshold" {
  type        = number
  description = "The Provisioned Throughput Exceeded threshold. If metric average is over this value, the alert will be triggered. Default is 0, we want to act as soon as possible."
  default     = 0
  validation {
    condition     = var.provisioned_throughput_exceeded_threshold >= 0
    error_message = "Provisioned throughput exceeded threshold must be a non-negative number."
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
}

#########################################
# Security and Networking Settings
#########################################

variable "minimal_tls_version" {
  type        = string
  description = "(Optional) Specifies the minimal TLS version for the CosmosDB account. Allowed values: Tls, Tls11, Tls12."
  default     = "Tls12"
  validation {
    condition     = contains(["Tls12"], var.minimal_tls_version)
    error_message = "The value for 'minimal_tls_version' must the minimal required: Tls12."
  }
}

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
