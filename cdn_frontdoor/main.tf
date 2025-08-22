locals {
  name_prefix          = var.dns_prefix_name
  cdn_location         = coalesce(var.cdn_location, var.location)
  storage_account_name = var.storage_account_name != null ? replace(var.storage_account_name, "-", "") : replace("${local.name_prefix}-sa", "-", "")

  # DNS helpers
  is_apex        = var.hostname == var.dns_zone_name
  hostname_label = local.is_apex ? "" : trimsuffix(replace(var.hostname, var.dns_zone_name, ""), ".")
  dns_txt_name   = local.hostname_label != "" ? "_dnsauth.${local.hostname_label}" : "_dnsauth"

  # Naming (clear suffixes)
  fd_profile_name    = "${local.name_prefix}-fd-prf"
  fd_endpoint_name   = "${local.name_prefix}-fd-ep"
  fd_origin_group    = "${local.name_prefix}-fd-og"
  fd_origin_primary  = "${local.name_prefix}-fd-or-primary"
  fd_route_default   = "${local.name_prefix}-fd-rt-default"
  fd_ruleset_global  = "${local.name_prefix}-fd-rs-global"
  fd_rule_global     = "${local.name_prefix}-fd-rule-global"
  fd_diag_name       = "${local.name_prefix}-fd-prf-diag"
  fd_secret_name     = "${local.name_prefix}-fd-secret"
  fd_customdom_name  = replace(var.hostname, ".", "-")
}

# Storage Account (static website)
module "cdn_storage_account" {
  source = "../storage_account"

  resource_group_name             = var.resource_group_name
  location                        = var.location

  name                            = local.storage_account_name
  account_kind                    = var.storage_account_kind
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  access_tier                     = var.storage_access_tier
  blob_versioning_enabled         = true
  allow_nested_items_to_be_public = var.storage_account_nested_items_public
  public_network_access_enabled   = var.storage_public_network_access_enabled
  advanced_threat_protection      = var.storage_account_advanced_threat_protection_enabled
  index_document                  = var.storage_account_index_document
  error_404_document              = var.storage_account_error_404_document
  tags                            = var.tags
}

# Front Door profile
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = local.fd_profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku_name
  tags                = var.tags
}

# Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = local.fd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

# Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = local.fd_origin_group
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  session_affinity_enabled = false

  health_probe {
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
    interval_in_seconds = 120
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 2
  }
}

# Origin (Primary - Storage static website)
resource "azurerm_cdn_frontdoor_origin" "origin_primary" {
  name                          = local.fd_origin_primary
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  enabled                        = true
  host_name                      = module.cdn_storage_account.primary_web_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = module.cdn_storage_account.primary_web_host
  certificate_name_check_enabled = false
  priority                       = 1
  weight                         = 1000
}

# Default route
resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = local.fd_route_default
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  https_redirect_enabled = var.https_rewrite_enabled
  forwarding_protocol    = "MatchRequest"
  link_to_default_domain = true
  enabled                = true

  # Associate Rule Set here (resource `azurerm_cdn_frontdoor_rule_set_route_association` DOES NOT exist)
  cdn_frontdoor_rule_set_ids = var.global_delivery_rule != null || length(var.delivery_rule) > 0 ? [azurerm_cdn_frontdoor_rule_set.this[0].id] : []

  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.origin_primary.id]
}

# Optional rule set for global headers and custom rules
resource "azurerm_cdn_frontdoor_rule_set" "this" {
  count                    = var.global_delivery_rule != null || length(var.delivery_rule) > 0 ? 1 : 0
  name                     = local.fd_ruleset_global
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

# Global delivery rule
resource "azurerm_cdn_frontdoor_rule" "global" {
  count                     = var.global_delivery_rule != null ? 1 : 0
  name                      = local.fd_rule_global
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = 1
  enabled                   = true
  behavior_on_match         = "Continue"

  actions {
    dynamic "response_header_action" {
      for_each = var.global_delivery_rule.modify_response_header_action
      iterator = rh
      content {
        action = rh.value.action
        header_action {
          header_name = rh.value.name
          value       = rh.value.value
        }
      }
    }
  }
}

# Additional rules based on delivery_rule variable
resource "azurerm_cdn_frontdoor_rule" "custom" {
  for_each                  = { for r in var.delivery_rule : r.name => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  enabled                   = try(each.value.enabled, true)
  behavior_on_match         = try(each.value.behavior_on_match, "Continue")

  dynamic "conditions" {
    for_each = try(each.value.url_path_conditions, [])
    iterator = c
    content {
      url_path_condition {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, null)
      }
    }
  }

  actions {
    dynamic "response_header_action" {
      for_each = try(each.value.modify_response_header_actions, [])
      iterator = rha
      content {
        action = rha.value.action
        header_action {
          header_name = rha.value.name
          value       = rha.value.value
        }
      }
    }

    dynamic "request_header_action" {
      for_each = try(each.value.modify_request_header_actions, [])
      iterator = rqa
      content {
        action = rqa.value.action
        header_action {
          header_name = rqa.value.name
          value       = rqa.value.value
        }
      }
    }

    dynamic "url_redirect_action" {
      for_each = try(each.value.url_redirect_actions, [])
      iterator = ura
      content {
        redirect_type        = ura.value.redirect_type
        destination_hostname = try(ura.value.hostname, null)
        protocol             = try(ura.value.protocol, null)
        destination_path     = try(ura.value.path, null)
        destination_fragment = try(ura.value.fragment, null)
        query_string         = try(ura.value.query_string, null)
      }
    }

    dynamic "url_rewrite_action" {
      for_each = try(each.value.url_rewrite_actions, [])
      iterator = urw
      content {
        source_pattern          = urw.value.source_pattern
        destination             = urw.value.destination
        preserve_unmatched_path = try(urw.value.preserve_unmatched_path, false)
      }
    }
  }
}

# Custom domain configuration

data "azurerm_dns_zone" "this" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_key_vault" "this" {
  count               = (var.dns_zone_name == var.hostname || var.custom_hostname_kv_enabled) && var.keyvault_id == null ? 1 : 0
  name                = var.keyvault_vault_name
  resource_group_name = var.keyvault_resource_group_name
}

locals {
  keyvault_id        = coalesce(var.keyvault_id, try(data.azurerm_key_vault.this[0].id, null))
  certificate_name   = replace(var.hostname, ".", "-")
  use_kv_certificate = var.dns_zone_name == var.hostname || var.custom_hostname_kv_enabled
}

data "azurerm_key_vault_certificate" "custom_domain" {
  count        = local.use_kv_certificate ? 1 : 0
  name         = local.certificate_name
  key_vault_id = local.keyvault_id
}

resource "azurerm_cdn_frontdoor_secret" "this" {
  count                    = local.use_kv_certificate ? 1 : 0
  name                     = local.fd_secret_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  secret {
    customer_certificate {
      key_vault_certificate_id = data.azurerm_key_vault_certificate.custom_domain[0].versionless_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  name                     = local.fd_customdom_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = data.azurerm_dns_zone.this.id
  host_name                = var.hostname

  tls {
    certificate_type        = local.use_kv_certificate ? "CustomerCertificate" : "ManagedCertificate"
    minimum_tls_version     = "TLS12"
    cdn_frontdoor_secret_id = local.use_kv_certificate ? azurerm_cdn_frontdoor_secret.this[0].id : null
  }
}

resource "azurerm_dns_txt_record" "domain_validation" {
  name                = local.dns_txt_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600

  record { value = azurerm_cdn_frontdoor_custom_domain.this.validation_token }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.this.id]

  depends_on = [
    azurerm_dns_txt_record.domain_validation
  ]
}

# DNS records
resource "azurerm_dns_a_record" "apex_hostname" {
  count               = var.create_dns_record && local.is_apex ? 1 : 0
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.this.id
}

resource "azurerm_dns_cname_record" "hostname" {
  count               = var.create_dns_record && !local.is_apex ? 1 : 0
  name                = local.hostname_label
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name
}

# Diagnostics (v4: enabled_log / enabled_metric)
resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings_cdn_profile" {
  name                       = local.fd_diag_name
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Key Vault Access Policy for AFD SP (if using KV cert)
resource "azurerm_key_vault_access_policy" "azure_cdn_frontdoor_policy" {
  count = var.custom_hostname_kv_enabled ? 1 : 0

  key_vault_id = local.keyvault_id
  tenant_id    = var.tenant_id
  object_id    = var.azuread_service_principal_azure_cdn_frontdoor_id

  secret_permissions = ["Get"]
  certificate_permissions = ["Get"]
}
