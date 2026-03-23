locals {
  admin_roles = [
    "manage-realm",
    "manage-users",
    "manage-clients",
    "manage-events",
    "view-realm",
    "view-users",
    "query-groups",
    "query-users",
    "query-clients"
  ]
}

# Data
data "keycloak_openid_client" "this" {
  for_each = { for i in keycloak_realm.this : i.name => i }

  realm_id  = "master"
  client_id = "${each.key}-realm"
}

data "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_rg
}

# Resource
resource "keycloak_realm" "this" {
  for_each = { for i in var.realms_configuration : i.name => i }

  realm        = each.value.name
  enabled      = each.value.enabled
  display_name = each.value.display_name

  # --- Themes ---
  login_theme   = each.value.login_theme
  account_theme = each.value.account_theme
  admin_theme   = each.value.admin_theme
  email_theme   = each.value.email_theme

  # --- Login Policies ---
  login_with_email_allowed       = each.value.login_with_email_allowed
  registration_allowed           = each.value.registration_allowed
  registration_email_as_username = each.value.registration_email_as_username
  edit_username_allowed          = each.value.edit_username_allowed
  reset_password_allowed         = each.value.reset_password_allowed
  remember_me                    = each.value.remember_me
  verify_email                   = each.value.verify_email
  duplicate_emails_allowed       = each.value.duplicate_emails_allowed
  ssl_required                   = each.value.ssl_required

  # --- Timeouts & Lifespans ---
  access_token_lifespan        = each.value.access_token_lifespan
  sso_session_idle_timeout     = each.value.sso_session_idle_timeout
  sso_session_max_lifespan     = each.value.sso_session_max_lifespan
  offline_session_idle_timeout = each.value.offline_session_idle_timeout
  access_code_lifespan_login   = each.value.access_code_lifespan_login

  # --- SMTP ---
  smtp_server {
    host                  = each.value.smtp_server.host
    port                  = each.value.smtp_server.port
    from                  = each.value.smtp_server.from
    from_display_name     = each.value.smtp_server.from_display_name
    reply_to              = each.value.smtp_server.reply_to
    reply_to_display_name = each.value.smtp_server.reply_to_display_name
    ssl                   = each.value.smtp_server.ssl
    starttls              = each.value.smtp_server.starttls

    auth {
      username = each.value.smtp_server.auth.username
      password = each.value.smtp_server.auth.password
    }
  }

  # --- Internationalization ---
  internationalization {
    supported_locales = each.value.internationalization.supported_locales
    default_locale    = each.value.internationalization.default_locale
  }

  # --- Security Defenses & Brute Force ---
  # Configures security headers to prevent Clickjacking, XSS, etc.
  security_defenses {
    headers {
      x_frame_options                     = each.value.security_defenses.headers.x_frame_options
      content_security_policy             = each.value.security_defenses.headers.content_security_policy
      content_security_policy_report_only = each.value.security_defenses.headers.content_security_policy_report_only
      x_content_type_options              = each.value.security_defenses.headers.x_content_type_options
      x_robots_tag                        = each.value.security_defenses.headers.x_robots_tag
      x_xss_protection                    = each.value.security_defenses.headers.x_xss_protection
      strict_transport_security           = each.value.security_defenses.headers.strict_transport_security
    }

    # Prevents brute force attacks by locking accounts or adding delays
    brute_force_detection {
      permanent_lockout                = each.value.security_defenses.brute_force_detection.permanent_lockout
      max_failure_wait_seconds         = each.value.security_defenses.brute_force_detection.max_failure_wait_seconds
      minimum_quick_login_wait_seconds = each.value.security_defenses.brute_force_detection.minimum_quick_login_wait_seconds
      wait_increment_seconds           = each.value.security_defenses.brute_force_detection.wait_increment_seconds
      quick_login_check_milli_seconds  = each.value.security_defenses.brute_force_detection.quick_login_check_milli_seconds
      max_login_failures               = each.value.security_defenses.brute_force_detection.max_login_failures
      failure_reset_time_seconds       = each.value.security_defenses.brute_force_detection.failure_reset_time_seconds
    }
  }

  # --- Custom Metadata ---
  attributes = each.value.attributes
}

resource "keycloak_openid_client" "this" {
  realm_id                 = "master"
  client_id                = "${var.domain}-terraform-admin"
  name                     = "Admin for project ${var.domain} only"
  enabled                  = true
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

resource "keycloak_openid_client_service_account_role" "this" {
  for_each = {
    for i in flatten([
      for realm in keycloak_realm.this : [
        for role in local.admin_roles : {
          key   = "${realm}-${role}"
          realm = realm
          role  = role
        }
      ]
    ]) : i.key => i
  }

  realm_id                = "master"
  service_account_user_id = keycloak_openid_client.this.service_account_user_id

  client_id = data.keycloak_openid_client.this[each.value.realm].id
  role      = each.value.role
}

resource "azurerm_key_vault_secret" "client_id" {
  name         = "keycloak-terraform-admin-client-id"
  value        = keycloak_openid_client.this.client_id
  key_vault_id = data.azurerm_key_vault.this.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "client_secret" {
  name         = "keycloak-terraform-admin-client-secret"
  value        = keycloak_openid_client.this.client_secret
  key_vault_id = data.azurerm_key_vault.this.id
  tags         = var.tags
}