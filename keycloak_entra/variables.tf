variable "prefix" {
  type = string
  validation {
    condition = (
      length(var.prefix) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type = string
  validation {
    condition = (
      length(var.env) <= 4
    )
    error_message = "Max length is 4 chars."
  }
}

variable "domain" {
  type    = string
  default = null
}

variable "ad_owners" {
  type        = list(string)
  description = "List of Azure Active Directory group display names that will be assigned as owners of the Keycloak Enterprise Application and App Registration"
  default     = []
}

variable "redirect_uris" {
  type        = list(string)
  description = "A list of authorized redirect URIs (Reply URLs) where Entra ID will send the authentication responses. These should point to the Keycloak broker endpoints"
}

variable "logout_url" {
  type        = string
  description = "The URL where Microsoft Entra ID will send a request when the user signs out"
  default     = null
}

variable "authorized_group_names" {
  type        = list(string)
  description = "List of AD group display names authorized to access the application and whose IDs will be mapped in Keycloak."
}