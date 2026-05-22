variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "key_vault_id" {
  type        = string
  description = "ID of the Key Vault"
}

variable "certificates" {
  description = "Map of client certificates to be issued"
  type = map(object({
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