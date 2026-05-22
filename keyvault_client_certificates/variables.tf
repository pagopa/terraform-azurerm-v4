
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
    key_vault_name     = string
    subject            = string
    validity_in_months = number
    san_dns_names      = optional(list(string), [])
  }))
  default = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
}