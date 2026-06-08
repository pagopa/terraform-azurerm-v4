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

variable "tags" {
  type        = map(string)
  description = "Azurerm test tags"
  default = {
    CreatedBy = "Terraform"
    Source    = "https://github.com/pagopa/terraform-azurerm-v4"
  }
}
