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

variable "name" {
  type        = string
  description = "(Required): Node pool name. Must not exceed 12 characters."
  validation {
    condition     = length(var.name) <= 12
    error_message = "The node pool name must not exceed 12 characters."
  }
}

variable "kubernetes_cluster_id" {
  type        = string
  description = "(Required): AKS cluster id."
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Required): Subnet id for the node pool."
}

variable "autoscale_enabled" {
  default     = true
  type        = bool
  description = "(Optional): Enable autoscaling for the node pool. Defaults to true."
}

variable "node_count_min" {
  type        = number
  description = "(Required): Minimum number of nodes in the node pool."
  validation {
    condition     = var.node_count_min >= module.idh_loader.idh_resource_configuration.node_min_allowed ? true : false
    error_message = "The node count minimum: ${var.node_count_min} must be greater than or equal to the allowed minimum: ${module.idh_loader.idh_resource_configuration.node_min_allowed} nodes for the resource tier."
  }
}

variable "node_count_max" {
  type        = number
  description = "(Required): Maximum number of nodes in the node pool."
}

variable "node_labels" {
  type        = map(string)
  description = "(Required): Map of labels to assign to the nodes."
}

variable "node_taints" {
  type        = list(string)
  default     = [""]
  description = "(Optional): List of taints to assign to the nodes."
}

variable "node_tags" {
  type        = map(any)
  description = "(Required): Map of tags to assign to the nodes."
}

variable "tags" {
  type        = map(any)
  description = "(Optional): Map of tags to assign to the resource."
}
