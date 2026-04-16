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

  domain_admin_composite_roles = [
    "manage-users", "manage-clients", "manage-events", "view-realm",
    "view-users", "query-groups", "query-users", "query-clients",
    "view-clients", "view-events"
  ]

  domain_viewer_composite_roles = [
    "view-realm", "view-users", "query-groups", "query-users",
    "query-clients", "view-clients", "view-events"
  ]

  admin_mappers = flatten([
    for realm in var.realms_configuration : [
      for i, group_id in var.admin_entra_group_ids : {
        key       = "${realm.name}-admin-${i}"
        realm_key = realm.name
        group_id  = group_id
      }
    ]
  ])

  viewer_mappers = flatten([
    for realm in var.realms_configuration : [
      for i, group_id in var.viewer_entra_group_ids : {
        key       = "${realm.name}-viewer-${i}"
        realm_key = realm.name
        group_id  = group_id
      }
    ]
  ])
}

# Data
data "keycloak_openid_client" "this" {
  for_each = { for i in var.realms_configuration : i.name => i }

  realm_id  = "master"
  client_id = "${each.key}-realm"
}

data "keycloak_role" "management_roles" {
  for_each = {
    for i in flatten([
      for realm in var.realms_configuration : [
        for role in distinct(concat(local.domain_admin_composite_roles, local.domain_viewer_composite_roles)) : {
          key       = "${realm.name}-${role}"
          realm_key = realm.name
          role_name = role
        }
      ]
    ]) : i.key => i
  }

  realm_id  = "master"
  client_id = data.keycloak_openid_client.this[each.value.realm_key].id
  name      = each.value.role_name
}

data "keycloak_openid_client" "master_realm_client" {
  realm_id  = "master"
  client_id = "master-realm"
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
  dynamic "smtp_server" {
    for_each = each.value.smtp_server != null ? [each.value.smtp_server] : []
    content {
      host                  = smtp_server.value.host
      port                  = smtp_server.value.port
      from                  = smtp_server.value.from
      from_display_name     = smtp_server.value.from_display_name
      reply_to              = smtp_server.value.reply_to
      reply_to_display_name = smtp_server.value.reply_to_display_name
      ssl                   = smtp_server.value.ssl
      starttls              = smtp_server.value.starttls

      auth {
        username = smtp_server.value.auth.username
        password = smtp_server.value.auth.password
      }
    }
  }

  # --- Internationalization ---
  dynamic "internationalization" {
    for_each = each.value.internationalization != null ? [each.value.internationalization] : []
    content {
      supported_locales = internationalization.value.supported_locales
      default_locale    = internationalization.value.default_locale
    }
  }

  # --- Security Defenses & Brute Force ---
  # Configures security headers to prevent Clickjacking, XSS, etc.
  dynamic "security_defenses" {
    for_each = each.value.security_defenses != null ? [each.value.security_defenses] : []
    content {
      headers {
        x_frame_options                     = security_defenses.value.headers.x_frame_options
        content_security_policy             = security_defenses.value.headers.content_security_policy
        content_security_policy_report_only = security_defenses.value.headers.content_security_policy_report_only
        x_content_type_options              = security_defenses.value.headers.x_content_type_options
        x_robots_tag                        = security_defenses.value.headers.x_robots_tag
        x_xss_protection                    = security_defenses.value.headers.x_xss_protection
        strict_transport_security           = security_defenses.value.headers.strict_transport_security
      }

      brute_force_detection {
        permanent_lockout                = security_defenses.value.brute_force_detection.permanent_lockout
        max_failure_wait_seconds         = security_defenses.value.brute_force_detection.max_failure_wait_seconds
        minimum_quick_login_wait_seconds = security_defenses.value.brute_force_detection.minimum_quick_login_wait_seconds
        wait_increment_seconds           = security_defenses.value.brute_force_detection.wait_increment_seconds
        quick_login_check_milli_seconds  = security_defenses.value.brute_force_detection.quick_login_check_milli_seconds
        max_login_failures               = security_defenses.value.brute_force_detection.max_login_failures
        failure_reset_time_seconds       = security_defenses.value.brute_force_detection.failure_reset_time_seconds
      }
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
      for realm in var.realms_configuration : [
        for role in local.admin_roles : {
          key   = "${realm.name}-${role}"
          realm = realm.name
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

resource "keycloak_openid_client_service_account_role" "master_global_read_access" {
  for_each = toset([
    "view-clients",
    "query-clients",
    "view-users",
    "query-users",
    "view-realm",
    "view-identity-providers"
  ])

  realm_id                = "master"
  service_account_user_id = keycloak_openid_client.this.service_account_user_id

  client_id = data.keycloak_openid_client.master_realm_client.id

  role = each.key
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

resource "keycloak_role" "domain_admin_role" {
  for_each = { for i in var.realms_configuration : i.name => i }

  realm_id    = "master"
  name        = "${var.domain}_${each.key}-realm_domain-admin-role"
  description = "Minimal admin: users, clients, events"

  composite_roles = [
    for role in local.domain_admin_composite_roles : data.keycloak_role.management_roles["${each.key}-${role}"].id
  ]
}

resource "keycloak_role" "domain_view_role" {
  for_each = { for i in var.realms_configuration : i.name => i }

  realm_id    = "master"
  name        = "${var.domain}_${each.key}-realm_domain-viewer-role"
  description = "Viewer"

  composite_roles = [
    for role in local.domain_viewer_composite_roles : data.keycloak_role.management_roles["${each.key}-${role}"].id
  ]
}

# --- Identity Provider Mappers ---

resource "keycloak_custom_identity_provider_mapper" "domain_admin_realm_mapper" {
  for_each = { for m in local.admin_mappers : m.key => m }

  realm                    = "master"
  name                     = "${var.domain}-${each.value.realm_key}-realm.entra-admin-${each.value.group_id}"
  identity_provider_alias  = "azure-entra"
  identity_provider_mapper = "oidc-role-idp-mapper"

  extra_config = {
    syncMode      = "FORCE"
    claim         = "groups"
    "claim.value" = each.value.group_id
    role          = keycloak_role.domain_admin_role[each.value.realm_key].name
  }
}

resource "keycloak_custom_identity_provider_mapper" "domain_view_realm_mapper" {
  for_each = { for m in local.viewer_mappers : m.key => m }

  realm                    = "master"
  name                     = "${var.domain}-${each.value.realm_key}-realm.entra-domain-viewer-${each.value.group_id}"
  identity_provider_alias  = "azure-entra"
  identity_provider_mapper = "oidc-role-idp-mapper"

  extra_config = {
    syncMode      = "FORCE"
    claim         = "groups"
    "claim.value" = each.value.group_id
    role          = keycloak_role.domain_view_role[each.value.realm_key].name
  }
}