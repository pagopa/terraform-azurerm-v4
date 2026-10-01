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

variable "stable_promotion_ids" {
  type        = map(string)
  description = "Promotion ids by certificate name, passed at apply time to promote a certificate to stable"
  default     = {}
}
