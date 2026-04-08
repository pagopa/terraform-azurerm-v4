variable "name" {
  type        = string
  description = "The name of the Azure Managed Redis instance."
}

variable "location" {
  type        = string
  description = "The location of the resource group."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the Managed Redis instance will be created."
}

variable "sku_name" {
  type        = string
  description = "The SKU of the Azure Managed Redis instance. Format: <Tier>_<Size>. Balanced: B0..B1000, ComputeOptimized: X3..X700, MemoryOptimized: M10..M2000, FlashOptimized: A250..A4500."
}

variable "zones" {
  type        = list(string)
  description = "(Optional) Specifies a list of Availability Zones where this Managed Redis instance should be located."
  default     = []
}

variable "high_availability_enabled" {
  type        = bool
  description = "(Optional) Whether high availability is enabled for this Managed Redis instance. Defaults to true."
  default     = true
}

variable "public_network_access" {
  type        = string
  description = "(Optional) Whether public network access is allowed. Possible values are Enabled and Disabled. Defaults to Disabled."
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be either 'Enabled' or 'Disabled'."
  }
}

variable "default_database" {
  type = object({
    access_keys_authentication_enabled = optional(bool, true)
    client_protocol                    = optional(string, "Encrypted")
    clustering_policy                  = optional(string, "OSSCluster")
    eviction_policy                    = optional(string, "NoEviction")
    persistence_rdb_frequency          = optional(string, null)
    persistence_aof_frequency          = optional(string, null)
  })
  description = "(Optional) Configuration block for the default database."
  default     = {}
  validation {
    condition     = contains(["Encrypted", "Plaintext"], var.default_database.client_protocol)
    error_message = "client_protocol must be either 'Encrypted' or 'Plaintext'."
  }
  validation {
    condition     = contains(["EnterpriseCluster", "OSSCluster", "NoCluster"], var.default_database.clustering_policy)
    error_message = "clustering_policy must be one of: EnterpriseCluster, OSSCluster, NoCluster."
  }
  validation {
    condition     = contains(["AllKeysLFU", "AllKeysLRU", "AllKeysRandom", "VolatileLFU", "VolatileLRU", "VolatileRandom", "VolatileTTL", "NoEviction"], var.default_database.eviction_policy)
    error_message = "eviction_policy must be one of: AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, NoEviction."
  }
}

variable "private_endpoint" {
  type = object({
    enabled              = bool
    subnet_id            = string
    private_dns_zone_ids = list(string)
  })
  description = "(Required) Enable private endpoint with required params. The expected DNS zone is privatelink.redis.azure.net."
}

variable "tags" {
  type = map(any)
}
