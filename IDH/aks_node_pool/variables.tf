variable "product_name" {
  type        = string
  description = "(Required) product_name used to identify the platform for which the resource will be created"
}

variable "env" {
  type        = string
  description = "(Required) Environment for which the resource will be created"
}

variable "idh_resource_tier" {
  type        = string
  description = "(Required) The name of IDH resource key to be created."
}

variable "kubernetes_cluster_id" {
  type        = string
  description = "(Required) AKS cluster id"
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Required) Subnet id for the node pool"
}

variable "name" {
  type        = string
  description = "(Required) Node pool name"
}

variable "tags" {
  type = map(any)
}

variable "vm_size" {
  type        = string
  default     = null
}

variable "os_disk_type" {
  type        = string
  default     = null
}

variable "os_disk_size_gb" {
  type        = number
  default     = null
}

variable "zones" {
  type        = list(string)
  default     = null
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = null
}

variable "enable_host_encryption" {
  type        = bool
  default     = null
}

variable "node_count_min" {
  type        = number
  default     = null
}

variable "node_count_max" {
  type        = number
  default     = null
}

variable "max_pods" {
  type        = number
  default     = null
}

variable "node_labels" {
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  type        = list(string)
  default     = null
}

variable "upgrade_settings_max_surge" {
  type        = string
  default     = null
}

variable "node_tags" {
  type        = map(any)
  default     = {}
}
