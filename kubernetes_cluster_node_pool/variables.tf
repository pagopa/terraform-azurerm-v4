variable "kubernetes_cluster_id" {
  type        = string
  description = "(Required): The ID of the AKS cluster"
}

variable "name" {
  type        = string
  description = "(Required): Node pool name. Must not exceed 12 characters."
  validation {
    condition     = length(var.name) <= 12
    error_message = "The node pool name must not exceed 12 characters."
  }
}

variable "vm_size" {
  type        = string
  description = "(Required): VM size for the nodes"
}

variable "os_disk_type" {
  type        = string
  description = "(Required): Type of OS disk"
  validation {
    condition     = (contains(var.vm_size, "Standard_B") ? var.os_disk_type == "Managed" : var.os_disk_type == "Ephemeral")
    error_message = "Use Managed when vm_size contains Standard_B, otherwise use Ephemeral"
  }
}

variable "os_disk_size_gb" {
  type        = number
  default     = 128
  description = "(Optional): OS disk size in GB"
}

variable "zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "(Optional): Availability zones"
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = false
  description = "(Optional): Enable Ultra SSD"
}

variable "enable_host_encryption" {
  type        = bool
  default     = false
  description = "(Optional): Enable host encryption"
}

variable "node_count_min" {
  type        = number
  description = "(Required): Minimum node count"
}

variable "node_count_max" {
  type        = number
  description = "(Required): Maximum node count"
}

variable "max_pods" {
  type        = number
  default     = 250
  description = "(Optional): Maximum pods per node"
}

variable "node_labels" {
  type        = map(string)
  default     = {}
  description = "(Optional): Node labels"
}

variable "node_taints" {
  type        = list(string)
  default     = []
  description = "(Optional): List of node taints."
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Required): Subnet ID for the node pool."
}

variable "upgrade_settings_max_surge" {
  type        = string
  default     = "33%"
  description = "(Optional): Max surge during upgrade."
}

variable "node_tags" {
  type        = map(any)
  description = "(Required): Additional tags for the node pool."
}

variable "tags" {
  type        = map(any)
  description = "(Required): Base tags."
}
