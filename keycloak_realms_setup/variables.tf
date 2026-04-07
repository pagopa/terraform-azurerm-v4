variable "domain" {
  type = string
}

variable "realms_configuration" {
  description = "Detailed configuration for Keycloak realms"
  type = list(object({
    # --- Basic & UI Settings ---
    name                          = string
    display_name                  = string
    enabled                       = bool
    login_theme                   = optional(string)
    account_theme                 = optional(string) # Theme for the user account management pages
    admin_theme                   = optional(string)
    email_theme                   = optional(string) # Theme for emails sent by this realm
    terraform_deletion_protection = optional(bool)

    # --- Login & Registration Flow ---
    login_with_email_allowed       = optional(bool)
    registration_allowed           = optional(bool)
    registration_email_as_username = optional(bool) # Use email as the username during registration
    edit_username_allowed          = optional(bool) # Allow users to change their username
    reset_password_allowed         = optional(bool)
    remember_me                    = optional(bool)
    verify_email                   = optional(bool)
    duplicate_emails_allowed       = optional(bool) # Allow multiple users to have the same email
    # --- Security & SSL ---
    ssl_required = optional(string) # 'none', 'external' or 'all'

    # --- Session & Token Timeouts ---
    access_token_lifespan        = optional(string) # Default: 5m
    sso_session_idle_timeout     = optional(string) # Default: 30m
    sso_session_max_lifespan     = optional(string) # Default: 10h
    offline_session_idle_timeout = optional(string) # Default: 30 days
    access_code_lifespan_login   = optional(string) # Time limit for login after code generation

    # --- SMTP Server Configuration ---
    smtp_server = optional(object({
      host                  = string
      port                  = string
      from                  = string
      from_display_name     = string
      reply_to              = string
      reply_to_display_name = string
      ssl                   = bool
      starttls              = bool
      auth = object({
        username = string
        password = string
      })
    }))

    # --- Internationalization ---
    internationalization = optional(object({
      supported_locales = list(string)
      default_locale    = string
    }))

    # --- Security Defenses (Headers) ---
    security_defenses = optional(object({
      headers = object({
        x_frame_options                     = string # Default: SAMEORIGIN
        content_security_policy             = string # Default: frame-src 'self'; frame-ancestors 'self'; object-src 'none';
        content_security_policy_report_only = string
        x_content_type_options              = string # Default: nosniff
        x_robots_tag                        = string # Default: none
        x_xss_protection                    = string # Default: 1; mode=block
        strict_transport_security           = string # Default: max-age=31536000; includeSubDomains
      })
      brute_force_detection = object({
        permanent_lockout                = bool # Lock user forever after max failures
        max_failure_wait_seconds         = number
        minimum_quick_login_wait_seconds = number
        wait_increment_seconds           = number
        quick_login_check_milli_seconds  = number
        max_login_failures               = number
        failure_reset_time_seconds       = number
      })
    }))

    # --- Extra Attributes ---
    attributes = optional(map(string)) # Custom metadata for the realm
  }))
  default = []
}

variable "key_vault_name" {
  type        = string
  description = "Key vault name"
}


variable "key_vault_rg" {
  type        = string
  description = "Key vault resource group"
}

variable "tags" {
  type = map(any)
}