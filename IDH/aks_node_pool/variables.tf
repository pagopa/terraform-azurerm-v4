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

variable "kubernetes_cluster_id" {
  type        = string
  description = "(Required): AKS cluster id."
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Required): Subnet id for the node pool."
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
  default     = null
  description = "(Optional): The size of the Virtual Machine."
}

variable "os_disk_type" {
  type        = string
  default     = null
  description = "(Optional): The type of the OS disk."
}

variable "os_disk_size_gb" {
  type        = number
  default = null
  description = "(Optional): The size of the OS disk in GB."
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "(Optional): List of availability zones where the node pool should be deployed."
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = null
  description = "(Optional): Enable ultra SSD for the node pool."
}

variable "enable_host_encryption" {
  type        = bool
  default     = null
  description = "(Optional): Enable host encryption for the node pool."
}

variable "node_count_min" {
  type        = number
  default     = null
  description = "(Optional): Minimum number of nodes in the node pool."
}

variable "node_count_max" {
  type        = number
  default     = null
  description = "(Optional): Maximum number of nodes in the node pool."
}

variable "max_pods" {
  type        = number
  default     = null
  description = "(Optional): Maximum number of pods per node."
}

variable "node_labels" {
  type        = map(string)
  description = "(Required): Map of labels to assign to the nodes."
}

variable "node_taints" {
  type        = list(string)
  description = "(Required): List of taints to assign to the nodes."
}

variable "upgrade_settings_max_surge" {
  type        = string
  description = "(Required): Max surge for node pool upgrades."
}

variable "node_tags" {
  type        = map(any)
  description = "(Required): Map of tags to assign to the nodes."
}

variable "tags" {
  type        = map(any)
  description = "(Optional): Map of tags to assign to the resource."
}
