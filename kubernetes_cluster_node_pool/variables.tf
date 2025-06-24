variable "kubernetes_cluster_id" {
  type        = string
  description = "The ID of the AKS cluster"
}

variable "name" {
  type        = string
  description = "Name of the node pool"
}

variable "vm_size" {
  type        = string
  description = "VM size for the nodes"
}

variable "os_disk_type" {
  type        = string
  default     = "Ephemeral"
  description = "Type of OS disk"
  validation {
    condition     = (contains(var.vm_size, "Standard_B") ? var.os_disk_type == "Managed" : var.os_disk_type == "Ephemeral")
    error_message = "Use Managed when vm_size contains Standard_B, otherwise use Ephemeral"
  }
}

variable "os_disk_size_gb" {
  type        = number
  default     = 128
  description = "OS disk size in GB"
}

variable "zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "Availability zones"
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = false
  description = "Enable Ultra SSD"
}

variable "enable_host_encryption" {
  type        = bool
  default     = false
  description = "Enable host encryption"
}

variable "node_count_min" {
  type        = number
  description = "Minimum node count"
}

variable "node_count_max" {
  type        = number
  description = "Maximum node count"
}

variable "max_pods" {
  type        = number
  default     = 250
  description = "Maximum pods per node"
}

variable "node_labels" {
  type        = map(string)
  default     = {}
  description = "Node labels"
}

variable "node_taints" {
  type        = list(string)
  default     = []
  description = "Node taints"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for the node pool"
}

variable "upgrade_settings_max_surge" {
  type        = string
  default     = "33%"
  description = "Max surge during upgrade"
}

variable "node_tags" {
  type        = map(any)
  description = "Additional tags for the node pool"
}

variable "tags" {
  type        = map(any)
  description = "Base tags"
}
