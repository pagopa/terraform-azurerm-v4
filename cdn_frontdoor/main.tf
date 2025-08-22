// Module: cdn_frontdoor
// Description: Provides Azure CDN Front Door profile, endpoint, origin group, origin and route using a storage account as origin.

locals {
  cdn_location         = coalesce(var.cdn_location, var.location)
  storage_account_name = var.storage_account_name != null ? replace(var.storage_account_name, "-", "") : replace("${var.dns_prefix_name}-sa", "-", "")
  is_apex              = var.hostname == var.dns_zone_name
  hostname_label       = local.is_apex ? "" : trimsuffix(replace(var.hostname, var.dns_zone_name, ""), ".")
  dns_txt_name         = local.hostname_label != "" ? "_dnsauth.${local.hostname_label}" : "_dnsauth"
}

/**
 * Storage account hosting static website
 */
module "cdn_storage_account" {
  source = "../storage_account"

  name                            = local.storage_account_name
  account_kind                    = var.storage_account_kind
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  access_tier                     = var.storage_access_tier
  blob_versioning_enabled         = true
  resource_group_name             = var.resource_group_name
  location                        = var.location
  allow_nested_items_to_be_public = var.storage_account_nested_items_public
  public_network_access_enabled   = var.storage_public_network_access_enabled
  advanced_threat_protection      = var.advanced_threat_protection_enabled
  index_document                  = var.index_document
  error_404_document              = var.error_404_document
  tags                            = var.tags
}

/**
 * Azure Front Door Standard/Premium profile
 */
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "${var.dns_prefix_name}-fd-profile"
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku_name
  tags                = var.tags
}

/**
 * Endpoint
 */
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                = "${var.dns_prefix_name}-fd-endpoint"
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
  enabled             = true
  tags                = var.tags
}

/**
 * Origin group and origin
 */
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                = "${var.dns_prefix_name}-og"
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name

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

resource "azurerm_cdn_frontdoor_origin" "storage" {
  name                = "storage"
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
  origin_group_name   = azurerm_cdn_frontdoor_origin_group.this.name

  host_name          = module.cdn_storage_account.primary_web_host
  http_port          = 80
  https_port         = 443
  origin_host_header = module.cdn_storage_account.primary_web_host
  priority           = 1
  weight             = 1000
}

/**
 * Default route
 */
resource "azurerm_cdn_frontdoor_route" "this" {
  name                = "${var.dns_prefix_name}-route"
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
  endpoint_name       = azurerm_cdn_frontdoor_endpoint.this.name
  origin_group_name   = azurerm_cdn_frontdoor_origin_group.this.name

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  https_redirect_enabled = var.https_rewrite_enabled
  forwarding_protocol    = "MatchRequest"
  link_to_default_domain = true

  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.storage.id]
}

/**
 * Optional rule set for global headers and custom rules
 */
resource "azurerm_cdn_frontdoor_rule_set" "this" {
  count               = var.global_delivery_rule != null || length(var.delivery_rule) > 0 ? 1 : 0
  name                = "${var.dns_prefix_name}-rules"
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
}

# Global delivery rule - only modify response headers for now
resource "azurerm_cdn_frontdoor_rule" "global" {
  count = var.global_delivery_rule != null ? 1 : 0

  name                = "global"
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
  rule_set_name       = azurerm_cdn_frontdoor_rule_set.this[0].name
  order               = 1

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
  for_each = { for r in var.delivery_rule : r.name => r }

  name                = each.value.name
  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
  rule_set_name       = azurerm_cdn_frontdoor_rule_set.this[0].name
  order               = each.value.order

  dynamic "conditions" {
    for_each = each.value.url_path_conditions
    iterator = c
    content {
      url_path_condition {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = c.value.negate_condition
      }
    }
  }

  actions {
    dynamic "response_header_action" {
      for_each = each.value.modify_response_header_actions
      iterator = rha
      content {
        action = rha.value.action
        header_action {
          header_name = rha.value.name
          value       = rha.value.value
        }
      }
    }

    dynamic "url_redirect_action" {
      for_each = each.value.url_redirect_actions
      iterator = ura
      content {
        redirect_type        = ura.value.redirect_type
        destination_hostname = ura.value.hostname
        protocol             = ura.value.protocol
        destination_path     = ura.value.path
        destination_fragment = ura.value.fragment
        query_string         = ura.value.query_string
      }
    }

    dynamic "url_rewrite_action" {
      for_each = each.value.url_rewrite_actions
      iterator = urw
      content {
        source_pattern          = urw.value.source_pattern
        destination             = urw.value.destination
        preserve_unmatched_path = urw.value.preserve_unmatched_path
      }
    }
  }
}

# Associate rule set to route when any rule exists
resource "azurerm_cdn_frontdoor_rule_set_route_association" "this" {
  count = (var.global_delivery_rule != null || length(var.delivery_rule) > 0) ? 1 : 0

  profile_name        = azurerm_cdn_frontdoor_profile.this.name
  resource_group_name = var.resource_group_name
  rule_set_name       = azurerm_cdn_frontdoor_rule_set.this[0].name
  route_name          = azurerm_cdn_frontdoor_route.this.name
}

/**
 * Custom domain configuration
 */

data "azurerm_dns_zone" "this" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_key_vault" "this" {
  count               = (var.dns_zone_name == var.hostname || var.custom_hostname_kv_enabled) && var.keyvault_id == null ? 1 : 0
  name                = var.keyvault_vault_name
  resource_group_name = var.keyvault_resource_group_name
  subscription_id     = var.keyvault_subscription_id
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
  name                     = "${var.dns_prefix_name}-secret"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  secret {
    customer_certificate {
      key_vault_certificate_id = data.azurerm_key_vault_certificate.custom_domain[0].versionless_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  name                     = replace(var.hostname, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = data.azurerm_dns_zone.this.id
  host_name                = var.hostname

  tls {
    certificate_type        = local.use_kv_certificate ? "CustomerCertificate" : "ManagedCertificate"
    minimum_tls_version     = "TLS12"
    cdn_frontdoor_secret_id = local.use_kv_certificate ? azurerm_cdn_frontdoor_secret.this[0].id : null
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.this.id]
}

resource "azurerm_dns_txt_record" "domain_validation" {
  name                = local.dns_txt_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this.validation_token
  }

  depends_on = [azurerm_cdn_frontdoor_route.this]
}

resource "azurerm_dns_a_record" "apex_hostname" {
  count               = var.create_dns_record && local.is_apex ? 1 : 0
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.this.id

  tags = var.tags

  depends_on = [azurerm_cdn_frontdoor_custom_domain_association.this]
}

resource "azurerm_dns_cname_record" "hostname" {
  count               = var.create_dns_record && !local.is_apex ? 1 : 0
  name                = local.hostname_label
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name

  tags = var.tags

  depends_on = [azurerm_cdn_frontdoor_custom_domain_association.this]
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings_cdn_profile" {
  name                       = "${var.dns_prefix_name}-cdn-profile-diagnostic-settings"
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_key_vault_access_policy" "azure_cdn_frontdoor_policy" {
  count = var.custom_hostname_kv_enabled ? 1 : 0

  key_vault_id = local.keyvault_id
  tenant_id    = var.tenant_id
  object_id    = var.azuread_service_principal_azure_cdn_frontdoor_id

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}

