############################################################
# Locals (naming, helpers, domain resolution)
############################################################
locals {
  name_prefix          = var.cdn_prefix_name
  storage_account_name = var.storage_account_name != null ? replace(var.storage_account_name, "-", "") : replace("${local.name_prefix}-sa", "-", "")

  # Naming
  fd_profile_name   = "${local.name_prefix}-cdn-profile"
  fd_endpoint_name  = "${local.name_prefix}-cdn-endpoint"
  fd_origin_group   = "origin-group"
  fd_origin_primary = "origin-group-primary"
  fd_route_default  = "route-default"
  fd_ruleset_global = replace("ruleset-global", "-", "")
  fd_rule_global    = replace("rule-global", "-", "")
  fd_diag_name      = "tf-diagnostics"

  # Multi-domain only
  domains_list = var.custom_domains
  domains      = { for d in local.domains_list : d.domain_name => d }

  is_apex        = { for k, v in local.domains : k => (v.domain_name == v.dns_name) }
  hostname_label = { for k, v in local.domains : k => (local.is_apex[k] ? "" : trimsuffix(replace(v.domain_name, v.dns_name, ""), ".")) }
  dns_txt_name   = { for k, v in local.domains : k => (local.is_apex[k] ? "_dnsauth" : "_dnsauth.${local.hostname_label[k]}") }

  # Certificate helpers (KV certs applied only when apex)
  keyvault_id = var.keyvault_id
}

############################################################
# Storage Account (static website)
############################################################
module "cdn_storage_account" {
  source = "../storage_account"

  resource_group_name = var.resource_group_name
  location            = var.location

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

############################################################
# Front Door profile & endpoint
############################################################
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = local.fd_profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku_name
  tags                = var.tags

  identity { type = "SystemAssigned" }
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = local.fd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

############################################################
# Origin Group & Origin (Static Website)
############################################################
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

resource "azurerm_cdn_frontdoor_origin" "storage_web_host" {
  name                          = local.fd_origin_primary
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  enabled                        = true
  host_name                      = module.cdn_storage_account.primary_web_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = module.cdn_storage_account.primary_web_host
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000
}

############################################################
# Rule Set (global) + Rules (global/custom)
############################################################
resource "azurerm_cdn_frontdoor_rule_set" "this" {
  count                    = length(var.global_delivery_rules) > 0 || length(var.delivery_rule) > 0 || length(var.delivery_rule_redirect) > 0 || length(var.delivery_rule_rewrite) > 0 || length(var.delivery_rule_request_scheme_condition) > 0 || length(var.delivery_rule_url_path_condition_cache_expiration_action) > 0 ? 1 : 0
  name                     = local.fd_ruleset_global
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

# -------------------------------------------------------------------
# Global Rule (headers + cache/qs override)
# -------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_rule" "global" {
  for_each                  = { for r in var.global_delivery_rules : tostring(r.order) => r }
  name                      = format("%s%04d", local.fd_rule_global, each.value.order)
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  actions {
    dynamic "request_header_action" {
      for_each = try(each.value.modify_request_header_action, [])
      iterator = rq
      content {
        header_action = rq.value.action
        header_name   = rq.value.name
        value         = rq.value.value
      }
    }

    dynamic "response_header_action" {
      for_each = try(each.value.modify_response_header_action, [])
      iterator = rh
      content {
        header_action = rh.value.action
        header_name   = rh.value.name
        value         = rh.value.value
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = (length(try(each.value.cache_expiration_action, [])) > 0 || length(try(each.value.cache_key_query_string_action, [])) > 0) ? [1] : []
      content {
        cache_behavior                = lookup({ Override = "OverrideAlways", SetIfMissing = "OverrideIfOriginMissing", BypassCache = "Disabled", HonorOrigin = "HonorOrigin" }, try(each.value.cache_expiration_action[0].behavior, "HonorOrigin"), "HonorOrigin")
        cache_duration                = try(each.value.cache_expiration_action[0].duration, null)
        query_string_caching_behavior = try(each.value.cache_key_query_string_action[0].behavior, null)
        query_string_parameters       = contains(["IncludeSpecifiedQueryStrings", "IgnoreSpecifiedQueryStrings"], try(each.value.cache_key_query_string_action[0].behavior, "")) && length(trimspace(try(each.value.cache_key_query_string_action[0].parameters, ""))) > 0 ? split(",", trimspace(each.value.cache_key_query_string_action[0].parameters)) : null
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

# -------------------------------------------------------------------
# URL path -> cache TTL + optional response header (back-compat)
# -------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_rule" "url_path_cache" {
  for_each                  = { for r in var.delivery_rule_url_path_condition_cache_expiration_action : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  conditions {
    url_path_condition {
      operator         = each.value.operator
      match_values     = [for v in each.value.match_values : trimprefix(v, "/")]
      negate_condition = false
      transforms       = []
    }
  }

  actions {
    route_configuration_override_action {
      cache_behavior = lookup({
        "Override"     = "OverrideAlways",
        "SetIfMissing" = "OverrideIfOriginMissing",
        "BypassCache"  = "Disabled",
        "HonorOrigin"  = "HonorOrigin"
        },
        "HonorOrigin",
      each.value.behavior)
      cache_duration = each.value.duration
    }

    response_header_action {
      header_action = each.value.response_action
      header_name   = each.value.response_name
      value         = each.value.response_value
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

# -------------------------------------------------------------------
# Scheme redirect (HTTP<->HTTPS) (back-compat)
# -------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_rule" "scheme_redirect" {
  for_each                  = { for r in var.delivery_rule_request_scheme_condition : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  conditions {
    request_scheme_condition {
      operator         = each.value.operator
      match_values     = each.value.match_values
      negate_condition = false
    }
  }

  actions {
    url_redirect_action {
      redirect_type        = each.value.url_redirect_action.redirect_type
      redirect_protocol    = try(each.value.url_redirect_action.protocol, null)
      destination_hostname = try(each.value.url_redirect_action.hostname, "")
      destination_path     = try(each.value.url_redirect_action.path, "")
      destination_fragment = try(each.value.url_redirect_action.fragment, "")
      query_string         = try(each.value.url_redirect_action.query_string, "")
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

# -------------------------------------------------------------------
# Redirect by Request URI (back-compat)
# -------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_rule" "redirect" {
  for_each                  = { for r in var.delivery_rule_redirect : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  conditions {
    request_uri_condition {
      operator         = each.value.operator
      match_values     = each.value.match_values
      negate_condition = false
      transforms       = []
    }
  }

  actions {
    url_redirect_action {
      redirect_type        = each.value.url_redirect_action.redirect_type
      redirect_protocol    = try(each.value.url_redirect_action.protocol, null)
      destination_hostname = try(each.value.url_redirect_action.hostname, "")
      destination_path     = try(each.value.url_redirect_action.path, "")
      destination_fragment = try(each.value.url_redirect_action.fragment, "")
      query_string         = try(each.value.url_redirect_action.query_string, "")
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

# =============================================================
# REWRITE-ONLY RULE (AFD Standard/Premium)
# =============================================================
resource "azurerm_cdn_frontdoor_rule" "rewrite_only" {
  for_each                  = { for r in var.delivery_rule_rewrite : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  conditions {
    dynamic "request_uri_condition" {
      for_each = [for c in each.value.conditions : c if c.condition_type == "request_uri_condition"]
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = c.value.negate_condition
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "request_uri_condition" {
      for_each = flatten([
        for c in each.value.conditions : [
          for v in c.match_values : {
            operator         = c.operator
            match_value      = v
            negate_condition = c.negate_condition
            transforms       = try(c.transforms, [])
          } if c.condition_type == "url_path_condition" && trimspace(v) == "/"
        ]
      ])
      iterator = ur
      content {
        operator         = ur.value.operator
        match_values     = [ur.value.match_value]
        negate_condition = ur.value.negate_condition
        transforms       = ur.value.transforms
      }
    }

    dynamic "url_path_condition" {
      for_each = [for c in each.value.conditions : c if c.condition_type == "url_path_condition" && length(compact([for v in c.match_values : trimprefix(v, "/")])) > 0]
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = compact([for v in c.value.match_values : trimprefix(v, "/")])
        negate_condition = c.value.negate_condition
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_file_extension_condition" {
      for_each = [for c in each.value.conditions : c if c.condition_type == "url_file_extension_condition"]
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = c.value.negate_condition
        transforms       = try(c.value.transforms, [])
      }
    }
  }

  actions {
    url_rewrite_action {
      source_pattern          = each.value.url_rewrite_action.source_pattern
      destination             = each.value.url_rewrite_action.destination
      preserve_unmatched_path = try(tobool(each.value.url_rewrite_action.preserve_unmatched_path), false)
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

############################################################
# Multi-domain resources
############################################################
data "azurerm_dns_zone" "zones" {
  for_each            = local.domains
  name                = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
}

# KV certificates only for apex domains
data "azurerm_key_vault_certificate" "certs" {
  for_each     = { for k, v in local.domains : k => v if local.is_apex[k] && var.keyvault_id != null }
  name         = replace(each.key, ".", "-")
  key_vault_id = local.keyvault_id
  depends_on = [
    azurerm_key_vault_access_policy.afd_policy,
    azurerm_cdn_frontdoor_profile.this,
  ]
}

# KV access policy for AFD identity
resource "azurerm_key_vault_access_policy" "afd_policy" {
  count                   = length(local.domains) > 0 && var.keyvault_id != null ? 1 : 0
  key_vault_id            = local.keyvault_id
  tenant_id               = var.tenant_id
  object_id               = azurerm_cdn_frontdoor_profile.this.identity[0].principal_id
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]

  depends_on = [azurerm_cdn_frontdoor_profile.this,
  ]

}

resource "azurerm_cdn_frontdoor_secret" "cert_secrets" {
  for_each                 = data.azurerm_key_vault_certificate.certs
  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.versionless_id
    }
  }

  depends_on = [azurerm_cdn_frontdoor_profile.this, ]

}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each                 = local.domains
  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = data.azurerm_dns_zone.zones[each.key].id
  host_name                = each.key

  tls {
    certificate_type        = contains(keys(azurerm_cdn_frontdoor_secret.cert_secrets), each.key) ? "CustomerCertificate" : "ManagedCertificate"
    cdn_frontdoor_secret_id = contains(keys(azurerm_cdn_frontdoor_secret.cert_secrets), each.key) ? azurerm_cdn_frontdoor_secret.cert_secrets[each.key].id : null
  }

  depends_on = [azurerm_cdn_frontdoor_profile.this, ]

}

#------------------------------------------------------------
# Validation (DNS TXT + A/CNAME records)
#------------------------------------------------------------
resource "azapi_resource_action" "afd_refresh_validation_token" {
  for_each = azurerm_cdn_frontdoor_custom_domain.this

  type        = "Microsoft.Cdn/profiles/customDomains@2025-04-15"
  resource_id = each.value.id
  action      = "refreshValidationToken"
  method      = "POST"

  depends_on = [azurerm_cdn_frontdoor_custom_domain.this]
}

resource "azurerm_dns_txt_record" "validation" {
  for_each = { for k, v in local.domains : k => v if try(v.enable_dns_records, true) }

  name                = local.dns_txt_name[each.key]
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = try(each.value.ttl, 3600)

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token
  }

  depends_on = [
    azapi_resource_action.afd_refresh_validation_token
  ]
}

# DNS apex A-record to endpoint
resource "azurerm_dns_a_record" "apex" {
  for_each            = { for k, v in local.domains : k => v if local.is_apex[k] && try(v.enable_dns_records, true) }
  name                = "@"
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = try(each.value.ttl, 3600)
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.this.id

  depends_on = [azurerm_cdn_frontdoor_profile.this, ]

}

# DNS subdomain CNAME to endpoint hostname
resource "azurerm_dns_cname_record" "subdomain" {
  for_each            = { for k, v in local.domains : k => v if !local.is_apex[k] && try(v.enable_dns_records, true) }
  name                = local.hostname_label[each.key]
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = try(each.value.ttl, 3600)
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name

  depends_on = [azurerm_cdn_frontdoor_profile.this, ]

}


############################################################
# Default Route
############################################################
resource "azurerm_cdn_frontdoor_route" "default_route" {
  name                          = local.fd_route_default
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  https_redirect_enabled = var.https_rewrite_enabled
  forwarding_protocol    = "MatchRequest"
  link_to_default_domain = true
  enabled                = true

  cdn_frontdoor_rule_set_ids = (
    length(var.global_delivery_rules) > 0
    || length(var.delivery_rule) > 0
    || length(var.delivery_rule_redirect) > 0
    || length(var.delivery_rule_rewrite) > 0
    || length(var.delivery_rule_request_scheme_condition) > 0
    || length(var.delivery_rule_url_path_condition_cache_expiration_action) > 0
  ) ? [azurerm_cdn_frontdoor_rule_set.this[0].id] : []

  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.storage_web_host.id]
  cdn_frontdoor_custom_domain_ids = [for d in azurerm_cdn_frontdoor_custom_domain.this : d.id]

  cache {
    query_string_caching_behavior = var.querystring_caching_behaviour
  }

  depends_on = [
    azurerm_cdn_frontdoor_secret.cert_secrets,
    azurerm_cdn_frontdoor_custom_domain.this,
    azurerm_dns_txt_record.validation,
    azurerm_dns_a_record.apex,
    azurerm_dns_cname_record.subdomain,

  ]
}

############################################################
# Diagnostics
############################################################
resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings_cdn_profile" {
  name                       = local.fd_diag_name
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}
