
variable "root_key_vault_id" {
  type        = string
  description = "ID of the Key Vault containing the Root CA (source)"
}

variable "root_key_vault_name" {
  type        = string
  description = "Name of the Key Vault containing the Root CA (source)"
}

variable "renewal_days_before_expiry" {
  type        = number
  description = "Days before cert-stable expiry to reissue the current certificate. Must be greater than stable_promotion_days_before_expiry."
  default     = 30
}

variable "stable_promotion_days_before_expiry" {
  type        = number
  description = "Days before cert-stable expiry to promote the current certificate to stable. Must be less than renewal_days_before_expiry."
  default     = 7
}

variable "certificates" {
  description = "Map of client certificates to be issued"
  type = map(object({
    key_vault_name     = string
    subject            = string
    validity_in_months = number
    san_dns_names      = optional(list(string), [])
  }))
  default = {}
}

variable "rotation_minutes_override" {
  type        = number
  default     = null
  description = "If set, replaces rotation_days with rotation_minutes on both time_rotating resources. For testing only — do not use in production."
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
}
