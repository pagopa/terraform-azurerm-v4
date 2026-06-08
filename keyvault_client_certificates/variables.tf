
variable "root_key_vault_id" {
  type        = string
  description = "ID of the Key Vault containing the Root CA (source)"
}

variable "root_key_vault_name" {
  type        = string
  description = "Name of the Key Vault containing the Root CA (source)"
}

variable "certificates" {
  description = "Map of client certificates to be issued"
  type = map(object({
    key_vault_name                      = string
    subject                             = string
    validity_in_months                  = number
    san_dns_names                       = optional(list(string), [])
    renewal_days_before_expiry          = optional(number, 30)
    stable_promotion_days_before_expiry = optional(number, 7)

  }))
  default = {}
}

variable "rotation_minutes_override" {
  type        = number
  default     = null
  description = "If set, replaces rotation_days with rotation_minutes on time_rotating.cert_rotation. For testing only — do not use in production."
}

variable "stable_rotation_minutes_override" {
  type        = number
  default     = null
  description = "If set, replaces rotation_days with rotation_minutes on time_rotating.cert_stable. For testing only — do not use in production."
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
}
