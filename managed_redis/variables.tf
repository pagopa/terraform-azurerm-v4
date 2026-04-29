# --- General Configuration ---

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
  description = "The SKU name for the managed Redis instance. Valid values: Balanced_B{0|1|3|5}, ComputeOptimized_X{3|5}."
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
    error_message = "SKU name must be a valid balanced or compute-optimized tier."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the managed Redis instance and related resources."
  default     = {}
}

# --- Instance Settings ---

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
      "AllKeysLFU", "AllKeysLRU", "AllKeysRandom", "VolatileLFU", "VolatileLRU", "VolatileRandom", "VolatileTTL", "NoEviction"
    ], var.eviction_policy)
    error_message = "Invalid Redis eviction policy."
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
    aof_enabled = optional(string)
    rdb_enabled = optional(string)
  })
  description = "Persistence configuration frequencies for RDB and AOF."
  default     = {}
}

variable "geo_replication_group_name" {
  type        = string
  description = "The name of the geo-replication group for the managed Redis instance."
  default     = null
}

variable "customer_managed_key_config" {
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  description = "Customer managed key configuration for encryption."
  default     = null
}

# --- Network / Private Endpoint ---

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

# --- Monitoring & Alerts Configuration ---

variable "alert_action_group_ids" {
  type        = list(string)
  description = "List of action group IDs where alerts will be sent."
  default     = []

  validation {
    condition = (
    var.cpu_alert_enabled || var.memory_alert_enabled || var.eviction_alert_enabled || var.connection_alert_enabled) ? length(var.alert_action_group_ids) > 0 : true

    error_message = "At least one alert (CPU, Memory, Eviction, or Connection) is enabled, so you must provide at least one Action Group ID in 'alert_action_group_ids'."
  }
}

# CPU Alerts
variable "cpu_alert_enabled" {
  type        = bool
  description = "Enable CPU usage alerts."
  default     = false
}

variable "cpu_threshold" {
  type        = number
  description = "The threshold percentage for CPU usage alerts (0-100)."
  default     = 80
}

# Memory Alerts
variable "memory_alert_enabled" {
  type        = bool
  description = "Enable memory usage alerts."
  default     = false
}

variable "memory_threshold" {
  type        = number
  description = "The threshold percentage for memory usage alerts (0-100)."
  default     = 80
}

# Eviction Alerts
variable "eviction_alert_enabled" {
  type        = bool
  description = "Enable alerts for key eviction events."
  default     = false
}

variable "eviction_threshold" {
  type        = number
  description = "The threshold for eviction events (usually 0 to catch any event)."
  default     = 0
}

# Connection Alerts
variable "connection_alert_enabled" {
  type        = bool
  description = "Enable connection count alerts."
  default     = false
}

variable "connection_threshold" {
  type        = number
  description = "The threshold for connected clients count."
  default     = 1000
}