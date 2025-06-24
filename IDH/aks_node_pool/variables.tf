variable "product_name" {
  type        = string
  description = "(Prefix) Required: Product name used to identify the platform for which the resource will be created."
}

variable "env" {
  type        = string
  description = "(Prefix) Required: Environment for which the resource will be created."
}

variable "idh_resource_tier" {
  type        = string
  description = "(Prefix) Required: The name of IDH resource tier to be created."
}

variable "kubernetes_cluster_id" {
  type        = string
  description = "(Prefix) Required: AKS cluster id."
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Prefix) Required: Subnet id for the node pool."
}

variable "name" {
  type        = string
  description = "(Prefix) Required: Node pool name. Must not exceed 12 characters."
  validation {
    condition     = length(var.name) <= 12
    error_message = "The node pool name must not exceed 12 characters."
  }
}

variable "tags" {
  type        = map(any)
  description = "(Prefix) Optional: Map of tags to assign to the resource."
}

variable "vm_size" {
  type        = string
  default     = null
  description = "(Prefix) Optional: The size of the Virtual Machine."
}

variable "os_disk_type" {
  type        = string
  default     = null
  description = "(Prefix) Optional: The type of the OS disk."
}

variable "os_disk_size_gb" {
  type        = number
  description = "(Prefix) Optional: The size of the OS disk in GB."
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "(Prefix) Optional: List of availability zones where the node pool should be deployed."
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = null
  description = "(Prefix) Optional: Enable ultra SSD for the node pool."
}

variable "enable_host_encryption" {
  type        = bool
  default     = null
  description = "(Prefix) Optional: Enable host encryption for the node pool."
}

variable "node_count_min" {
  type        = number
  default     = null
  description = "(Prefix) Optional: Minimum number of nodes in the node pool."
}

variable "node_count_max" {
  type        = number
  default     = null
  description = "(Prefix) Optional: Maximum number of nodes in the node pool."
}

variable "max_pods" {
  type        = number
  default     = null
  description = "(Prefix) Optional: Maximum number of pods per node."
}

variable "node_labels" {
  type        = map(string)
  default     = {}
  description = "(Prefix) Optional: Map of labels to assign to the nodes."
}

variable "node_taints" {
  type        = list(string)
  default     = null
  description = "(Prefix) Optional: List of taints to assign to the nodes."
}

variable "upgrade_settings_max_surge" {
  type        = string
  default     = null
  description = "(Prefix) Optional: Max surge for node pool upgrades."
}

variable "node_tags" {
  type        = map(any)
  default     = {}
  description = "(Prefix) Optional: Map of tags to assign to the nodes."
}
