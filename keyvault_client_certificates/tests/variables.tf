variable "prefix" {
  description = "Resource prefix"
  type        = string
  default     = "dvopla-2"
}

variable "location" {
  description = "Resource location"
  type        = string
  default     = "italynorth"
}

variable "rotation_minutes_override" {
  description = "If set, replaces rotation_days with rotation_minutes on cert_rotation (for testing only)"
  type        = number
  default     = 10
}

variable "stable_rotation_minutes_override" {
  description = "If set, replaces rotation_days with rotation_minutes on cert_stable (for testing only)"
  type        = number
  default     = 15
}

variable "tags" {
  type        = map(string)
  description = "Azurerm test tags"
  default = {
    CreatedBy = "Terraform"
    Source    = "https://github.com/pagopa/terraform-azurerm-v4"
  }
}
