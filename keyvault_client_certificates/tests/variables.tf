variable "prefix" {
  description = "Resource prefix"
  type        = string
  default     = "dvopla"
}

variable "location" {
  description = "Resource location"
  type        = string
  default     = "italynorth"
}

variable "renewal_days_before_expiry" {
  description = "Days before cert-stable expiry to reissue the current certificate (X)"
  type        = number
  default     = 30
}

variable "stable_promotion_days_before_expiry" {
  description = "Days before cert-stable expiry to promote current to stable (Y)"
  type        = number
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Azurerm test tags"
  default = {
    CreatedBy = "Terraform"
    Source    = "https://github.com/pagopa/terraform-azurerm-v4"
  }
}
