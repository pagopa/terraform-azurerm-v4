variable "prefix" {
  type        = string
  description = "Resource prefix for all resources"
  default     = "cdntest"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "italynorth"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    Project     = "TerraformCDNv2"
    Environment = "Test"
    ManagedBy   = "Terraform"
  }
}
