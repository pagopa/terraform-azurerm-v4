
variable "name" {
  type        = string
  description = "Service account name"
}

variable "namespace" {
  type        = string
  description = "Service account namespace"
}

variable "custom_service_account_default_secret_name" {
  type        = string
  description = "Service account custom secret name"
  default     = ""
}


