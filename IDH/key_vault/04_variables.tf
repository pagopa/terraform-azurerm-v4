variable "prefix" {
  type        = string
  description = "(Required) prefix used to identify the platform for which the resource will be created"
  validation {
    condition = (
      length(var.prefix) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type        = string
  description = "(Required) Environment for which the resource will be created"
}

variable "idh_resource" {
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
  type    = string
  default = null
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



variable "tags" {
  type = map(any)
}
