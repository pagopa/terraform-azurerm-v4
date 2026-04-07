# keycloak_entra

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_keycloak"></a> [keycloak](#requirement\_keycloak) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.client_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.client_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [keycloak_openid_client.this](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/openid_client) | resource |
| [keycloak_openid_client_service_account_role.this](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/openid_client_service_account_role) | resource |
| [keycloak_realm.this](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/realm) | resource |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [keycloak_openid_client.this](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/data-sources/openid_client) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain"></a> [domain](#input\_domain) | n/a | `string` | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Key vault name | `string` | n/a | yes |
| <a name="input_key_vault_rg"></a> [key\_vault\_rg](#input\_key\_vault\_rg) | Key vault resource group | `string` | n/a | yes |
| <a name="input_realms_configuration"></a> [realms\_configuration](#input\_realms\_configuration) | Detailed configuration for Keycloak realms | <pre>list(object({<br/>    # --- Basic & UI Settings ---<br/>    name                          = string<br/>    display_name                  = string<br/>    enabled                       = bool<br/>    login_theme                   = optional(string)<br/>    account_theme                 = optional(string) # Theme for the user account management pages<br/>    admin_theme                   = optional(string)<br/>    email_theme                   = optional(string) # Theme for emails sent by this realm<br/>    terraform_deletion_protection = optional(bool)<br/><br/>    # --- Login & Registration Flow ---<br/>    login_with_email_allowed       = optional(bool)<br/>    registration_allowed           = optional(bool)<br/>    registration_email_as_username = optional(bool) # Use email as the username during registration<br/>    edit_username_allowed          = optional(bool) # Allow users to change their username<br/>    reset_password_allowed         = optional(bool)<br/>    remember_me                    = optional(bool)<br/>    verify_email                   = optional(bool)<br/>    duplicate_emails_allowed       = optional(bool) # Allow multiple users to have the same email<br/>    # --- Security & SSL ---<br/>    ssl_required = optional(string) # 'none', 'external' or 'all'<br/><br/>    # --- Session & Token Timeouts ---<br/>    access_token_lifespan        = optional(string) # Default: 5m<br/>    sso_session_idle_timeout     = optional(string) # Default: 30m<br/>    sso_session_max_lifespan     = optional(string) # Default: 10h<br/>    offline_session_idle_timeout = optional(string) # Default: 30 days<br/>    access_code_lifespan_login   = optional(string) # Time limit for login after code generation<br/><br/>    # --- SMTP Server Configuration ---<br/>    smtp_server = optional(object({<br/>      host                  = string<br/>      port                  = string<br/>      from                  = string<br/>      from_display_name     = string<br/>      reply_to              = string<br/>      reply_to_display_name = string<br/>      ssl                   = bool<br/>      starttls              = bool<br/>      auth = object({<br/>        username = string<br/>        password = string<br/>      })<br/>    }))<br/><br/>    # --- Internationalization ---<br/>    internationalization = optional(object({<br/>      supported_locales = list(string)<br/>      default_locale    = string<br/>    }))<br/><br/>    # --- Security Defenses (Headers) ---<br/>    security_defenses = optional(object({<br/>      headers = object({<br/>        x_frame_options                     = string # Default: SAMEORIGIN<br/>        content_security_policy             = string # Default: frame-src 'self'; frame-ancestors 'self'; object-src 'none';<br/>        content_security_policy_report_only = string<br/>        x_content_type_options              = string # Default: nosniff<br/>        x_robots_tag                        = string # Default: none<br/>        x_xss_protection                    = string # Default: 1; mode=block<br/>        strict_transport_security           = string # Default: max-age=31536000; includeSubDomains<br/>      })<br/>      brute_force_detection = object({<br/>        permanent_lockout                = bool # Lock user forever after max failures<br/>        max_failure_wait_seconds         = number<br/>        minimum_quick_login_wait_seconds = number<br/>        wait_increment_seconds           = number<br/>        quick_login_check_milli_seconds  = number<br/>        max_login_failures               = number<br/>        failure_reset_time_seconds       = number<br/>      })<br/>    }))<br/><br/>    # --- Extra Attributes ---<br/>    attributes = optional(map(string)) # Custom metadata for the realm<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
