variable "resource_group_prefix" {
  type        = string
  description = "Prefix for the resource group names"
}

variable "location" {
  type        = string
  description = "The Azure region where the resources should be created"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to the resources"
  default     = {}
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to be merged with the default tags"
  default     = {}
}

variable "additional_resource_groups" {
  type        = list(string)
  description = "List of additional resource groups to create besides the default ones"
  default     = []
}

variable "enable_resource_locks" {
  type        = bool
  description = "Whether to enable CanNotDelete locks on the resource groups"
  default     = true
}
