variable "product_name" {
  type        = string
  description = "(Required) product_name used to identify the platform for which the resource will be created"
  validation {
    condition = (
      length(var.product_name) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type        = string
  description = "(Required) Environment for which the resource will be created"
}

variable "idh_resource_tier" {
  type        = string
  description = "(Required) The name od IDH resource key to be created."
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "terraform_cloud_object_id" {
  type        = string
  default     = null
  description = "Terraform cloud object id to create its access policy."
}

variable "sec_log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log analytics workspace security (it should be in a different subscription)."
}

variable "sec_storage_id" {
  type        = string
  default     = null
  description = "Storage Account security (it should be in a different subscription)."
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "Enable private endpoint"
  default     = false
}

variable "private_dns_zones_ids" {
  description = "Private DNS Zones where the private endpoint will be created"
  type        = list(string)
  default     = []
}


variable "private_endpoint_resource_group_name" {
  description = "Name of the resource group where the private endpoint will be created"
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "The id of the subnet that will be used for the private endpoint."
}

variable "tags" {
  type = map(any)
}
