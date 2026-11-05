variable "display_name" {
  type        = string
  description = "Full display name of the App Registration and Enterprise Application (e.g. 'myprj-d-argocd'). No naming convention is enforced by the module."

  validation {
    condition     = length(var.display_name) <= 120
    error_message = "display_name must be at most 120 characters."
  }
}

variable "ad_user_owners" {
  type        = list(string)
  description = "List of Azure Active Directory user principal names that will be assigned as owners of the Enterprise Application and App Registration"
  default     = []
}

variable "redirect_uris" {
  type        = list(string)
  description = "A list of authorized redirect URIs (Reply URLs) where Entra ID will send the authentication responses"
}

variable "logout_url" {
  type        = string
  description = "The URL where Microsoft Entra ID will send a request when the user signs out"
  default     = null
}

variable "authorized_group_names" {
  type        = list(string)
  description = "List of AD group display names authorized to access the application. Only these groups are emitted in the 'groups' claim."
}

variable "client_secret_display_name" {
  type        = string
  description = "Display name of the generated client secret"
  default     = "OIDC client secret"
}
