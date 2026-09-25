
variable "root_key_vault_id" {
  type        = string
  description = "ID of the Key Vault containing the Root CA (source)"
}

variable "root_key_vault_name" {
  type        = string
  description = "Name of the Key Vault containing the Root CA (source)"
}

variable "certificates" {
  description = "Map of client certificates to be issued. Promotion to the stable secrets is driven by stable_promotion_ids."
  type = map(object({
    key_vault_name             = string
    subject                    = string
    validity_in_months         = number
    san_dns_names              = optional(list(string), [])
    renewal_days_before_expiry = optional(number, 60)
  }))
  default = {}
}

variable "stable_promotion_ids" {
  type        = map(string)
  default     = {}
  description = "Promotion ids by certificate name, passed by pipelines at apply time (e.g. -var 'stable_promotion_ids={\"my-cert\":\"<build id>\"}'): a certificate (<name>-pfx) is promoted to its stable secrets (<name>-stable-*) when its id changes. Runs omitting it never promote: the first deploy of a certificate must list it, otherwise no -stable-* secret is created."

  validation {
    condition     = alltrue([for name in keys(var.stable_promotion_ids) : contains(keys(var.certificates), name)])
    error_message = "stable_promotion_ids contains a name that is not in certificates."
  }

  validation {
    condition     = alltrue([for id in values(var.stable_promotion_ids) : can(regex("^[A-Za-z0-9._-]+$", id))])
    error_message = "stable_promotion_ids values must be non-empty strings of letters, digits, '.', '_' or '-'."
  }
}

# For testing only: overrides rotation_days with rotation_minutes
# variable "rotation_minutes_override" {
#   type        = number
#   default     = null
#   description = "If set, replaces rotation_days with rotation_minutes on time_rotating.cert_rotation. For testing only — do not use in production."
# }

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
}
