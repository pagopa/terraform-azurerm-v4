
variable "root_key_vault_id" {
  type        = string
  description = "ID of the Key Vault containing the Root CA (source)"
}

variable "root_key_vault_name" {
  type        = string
  description = "Name of the Key Vault containing the Root CA (source)"
}

variable "certificates" {
  description = "Map of client certificates to be issued. Set stable_promotion_id to a new value (e.g. the promotion date) to promote that certificate (<name>-pfx) to its stable secrets (<name>-stable-*); null never promotes. The first deploy of a certificate must set it, otherwise no -stable-* secret is created."
  type = map(object({
    key_vault_name             = string
    subject                    = string
    validity_in_months         = number
    san_dns_names              = optional(list(string), [])
    renewal_days_before_expiry = optional(number, 60)
    stable_promotion_id        = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for cert in values(var.certificates) :
      cert.stable_promotion_id == null || can(regex("^[A-Za-z0-9._-]+$", cert.stable_promotion_id))
    ])
    error_message = "stable_promotion_id must be null or a non-empty string of letters, digits, '.', '_' or '-'."
  }
}

variable "stable_promotion_ids" {
  type        = map(string)
  default     = {}
  description = "Promotion ids by certificate name, alternative to stable_promotion_id in certificates. Meant to be passed by pipelines at apply time (e.g. -var 'stable_promotion_ids={\"my-cert\":\"<build id>\"}'): a certificate is promoted when its id changes; runs omitting it never promote. A certificate listed here must not set stable_promotion_id."

  validation {
    condition     = alltrue([for name in keys(var.stable_promotion_ids) : contains(keys(var.certificates), name)])
    error_message = "stable_promotion_ids contains a name that is not in certificates."
  }

  validation {
    condition = alltrue([
      for name in keys(var.stable_promotion_ids) :
      !contains(keys(var.certificates), name) || var.certificates[name].stable_promotion_id == null
    ])
    error_message = "A certificate listed in stable_promotion_ids must not set stable_promotion_id: use one source only, or runs without stable_promotion_ids would promote it again."
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
