variable "location" {
  type        = string
  description = "The Azure location where the managed Redis instance will be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the managed Redis instance."
  nullable    = false

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 63
    error_message = "The name must be between 1 and 63 characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the managed Redis instance will be created."
  nullable    = false
}

variable "sku_name" {
  type        = string
  description = "The SKU name for the managed Redis instance. Valid values: Balanced_B{0|1|3|5|10|20|50|100|150|250|350|500|700|1000}, ComputeOptimized_X{3|5|10|20|50|100|150|250|350|500|700}, FlashOptimized_A{250|500|700|1000|1500|2000|4500}, MemoryOptimized_M{10|20|50|100|150|250|350|500|1000|1500|2000}."
  nullable    = false

  validation {
    condition = contains([
      "Balanced_B0",
      "Balanced_B1",
      "Balanced_B3",
      "Balanced_B5",
      "ComputeOptimized_X3",
      "ComputeOptimized_X5",
    ], var.sku_name)
    error_message = "SKU name must be a valid balanced and compute-optimized."
  }
}

variable "high_availability_enabled" {
  type        = bool
  description = "Enable high availability for the managed Redis instance."
  default     = true
}

variable "public_network_access" {
  type        = string
  description = "Public network access setting (Enabled or Disabled)."
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "Public network access must be 'Enabled' or 'Disabled'."
  }
}

variable "access_keys_authentication_enabled" {
  type        = bool
  description = "Enable access keys authentication for the default database."
  default     = true
}

variable "client_protocol" {
  type        = string
  description = "Client protocol version (Encrypted or Plaintext)."
  default     = "Encrypted"

  validation {
    condition     = contains(["Encrypted", "Plaintext"], var.client_protocol)
    error_message = "Client protocol must be 'Encrypted' or 'Plaintext'."
  }
}

variable "clustering_policy" {
  type        = string
  description = "Clustering policy (EnterpriseCluster or OSSCluster)."
  default     = "EnterpriseCluster"

  validation {
    condition     = contains(["EnterpriseCluster", "OSSCluster"], var.clustering_policy)
    error_message = "Clustering policy must be EnterpriseCluster or OSSCluster."
  }
}

variable "eviction_policy" {
  type        = string
  description = "Eviction policy (AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, NoEviction)."
  default     = "AllKeysLRU"

  validation {
    condition = contains([
      "AllKeysLFU",
      "AllKeysLRU",
      "AllKeysRandom",
      "VolatileLFU",
      "VolatileLRU",
      "VolatileRandom",
      "VolatileTTL",
      "NoEviction"
    ], var.eviction_policy)
    error_message = "Eviction policy must be a valid Redis eviction policy: AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, or NoEviction."
  }
}

variable "modules" {
  type = list(object({
    name = string
  }))
  description = "List of modules to load (RediSearch, RedisJSON, RedisBloom, RedisTimeSeries, RedisAI, RedisGears)."
  default     = []
}

variable "persistence_configuration" {
  type = object({
    aof_enabled = bool
    rdb_enabled = bool
  })
  description = "Persistence configuration for RDB and AOF."
  default = {
    aof_enabled = false
    rdb_enabled = false
  }
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "Enable private endpoint for the managed Redis instance."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The subnet ID for the private endpoint (required if private_endpoint_enabled is true)."
  default     = null
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "The list of private DNS zone IDs for the private endpoint."
  default     = []
}

variable "customer_managed_key_config" {
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  description = "Customer managed key configuration for encryption."
  default     = null
}

variable "alert_action_group_ids" {
  type        = list(string)
  description = "List of Azure Monitor action group IDs for alerts."
  default     = []
}

variable "enable_cpu_alerts" {
  type        = bool
  description = "Enable alerts for high CPU usage."
  default     = false
}

variable "cpu_usage_percentage_threshold" {
  type        = number
  description = "Threshold percentage for CPU usage alert."
  default     = 80

  validation {
    condition     = var.cpu_usage_percentage_threshold > 0 && var.cpu_usage_percentage_threshold <= 100
    error_message = "CPU usage percentage threshold must be between 1 and 100."
  }
}

variable "enable_memory_alerts" {
  type        = bool
  description = "Enable alerts for high memory usage."
  default     = false
}

variable "memory_usage_percentage_threshold" {
  type        = number
  description = "Threshold percentage for memory usage alert."
  default     = 80

  validation {
    condition     = var.memory_usage_percentage_threshold > 0 && var.memory_usage_percentage_threshold <= 100
    error_message = "Memory usage percentage threshold must be between 1 and 100."
  }
}

variable "enable_eviction_alerts" {
  type        = bool
  description = "Enable alerts for eviction events."
  default     = false
}

variable "enable_connection_alerts" {
  type        = bool
  description = "Enable alerts for high connection count."
  default     = false
}

variable "connection_count_threshold" {
  type        = number
  description = "Threshold for connection count alert."
  default     = 5000
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the managed Redis instance and related resources."
  default     = {}
}
