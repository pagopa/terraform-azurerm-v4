variable "name" {
  type        = string
  description = "(Required) Resource name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Resource location."
}

variable "subnet_id" {
  type        = string
  description = "(Optional) Subnet id if the environment is in a custom virtual network"

  default = null
}

variable "zone_redundant" {
  type        = bool
  description = "Deploy multi zone environment. Can be true only if a subnet_id is provided"
  default     = false
}

variable "internal_load_balancer" {
  type        = bool
  description = "Internal Load Balancing Mode. Can be true only if a subnet_id is provided"
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource id"
}

variable "private_endpoint_config" {
  description = "Configuration for private endpoint and DNS zones for Container Apps Environment"
  type = object({
    enabled              = bool
    subnet_id            = optional(string, null)
    private_dns_zone_ids = optional(list(string), [])
  })
  default = {
    enabled = false
  }
}

variable "workload_profiles" {
  description = "Workload profiles list"
  type = list(object({
    name      = string
    type      = string
    min_count = number
    max_count = number
  }))
  default = []
}

variable "tags" {
  type = map(any)
}
