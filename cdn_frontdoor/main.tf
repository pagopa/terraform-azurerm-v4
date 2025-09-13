############################################################
# Locals (naming, helpers, domain resolution)
############################################################
/* Defines naming helpers, domain-derived maps, and Key Vault reference for certs */
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
/* Provisions a secure Storage Account configured for static website hosting */
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

############################################################
# Front Door profile & endpoint
############################################################
/* Creates the Azure Front Door Standard/Premium profile with managed identity */
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = local.fd_profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku_name
  tags                = var.tags

  identity { type = "SystemAssigned" }
}

/* Exposes an AFD endpoint to serve traffic for routes and custom domains */
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = local.fd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

############################################################
# Origin Group & Origin (Static Website)
############################################################
/* Defines health probing and load-balancing policy for origins */
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

/* Registers the Storage static website host as the primary origin */
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
/* Container for global delivery rules attached to routes */
resource "azurerm_cdn_frontdoor_rule_set" "this" {
  count                    = length(var.global_delivery_rules) > 0 || length(var.delivery_custom_rules) > 0 || length(var.delivery_rule_redirects) > 0 || length(var.delivery_rule_rewrites) > 0 || length(var.delivery_rule_request_scheme_condition) > 0 || length(var.delivery_rule_url_path_condition_cache_expiration_action) > 0 ? 1 : 0
  name                     = local.fd_ruleset_global
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

/* Applies global header mutations and cache/querystring overrides */
resource "azurerm_cdn_frontdoor_rule" "rule_global" {
  for_each                  = { for r in var.global_delivery_rules : tostring(r.order) => r }
  name                      = format("%s%04d", local.fd_rule_global, each.value.order)
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  actions {
    dynamic "request_header_action" {
      for_each = try(each.value.modify_request_header_actions, [])
      iterator = rq
      content {
        header_action = rq.value.action
        header_name   = rq.value.name
        value         = rq.value.value
      }
    }

    dynamic "response_header_action" {
      for_each = try(each.value.modify_response_header_actions, [])
      iterator = rh
      content {
        header_action = rh.value.action
        header_name   = rh.value.name
        value         = rh.value.value
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = (length(try(each.value.cache_expiration_actions, [])) > 0 || length(try(each.value.cache_key_query_string_actions, [])) > 0) ? [1] : []
      content {
        cache_behavior                = lookup({ Override = "OverrideAlways", SetIfMissing = "OverrideIfOriginMissing", BypassCache = "Disabled", HonorOrigin = "HonorOrigin" }, try(each.value.cache_expiration_actions[0].behavior, "HonorOrigin"), "HonorOrigin")
        cache_duration                = try(each.value.cache_expiration_actions[0].duration, null)
        query_string_caching_behavior = try(each.value.cache_key_query_string_actions[0].behavior, null)
        query_string_parameters       = contains(["IncludeSpecifiedQueryStrings", "IgnoreSpecifiedQueryStrings"], try(each.value.cache_key_query_string_actions[0].behavior, "")) && length(trimspace(try(each.value.cache_key_query_string_actions[0].parameters, ""))) > 0 ? split(",", trimspace(each.value.cache_key_query_string_actions[0].parameters)) : null
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

/* Sets per-path caching TTL and optional response header */
resource "azurerm_cdn_frontdoor_rule" "rule_url_path_cache" {
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
      }, each.value.behavior, "HonorOrigin")
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

/* Redirects based on request scheme (e.g., force HTTPS) */
resource "azurerm_cdn_frontdoor_rule" "rule_scheme_redirect" {
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

/* Redirects based on Request URI and/or URL path patterns */
resource "azurerm_cdn_frontdoor_rule" "rule_redirect" {
  for_each                  = { for r in var.delivery_rule_redirects : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  conditions {
    dynamic "request_uri_condition" {
      for_each = try(each.value.request_uri_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_path_condition" {
      for_each = [for c in each.value.url_path_conditions : c]
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = compact([for v in c.value.match_values : v])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }
  }

  actions {
    dynamic "url_redirect_action" {
      for_each = each.value.url_redirect_actions
      iterator = c
      content {
        redirect_type        = c.value.redirect_type
        redirect_protocol    = try(c.value.protocol, null)
        destination_hostname = try(c.value.hostname, "")
        destination_path     = try(c.value.path, "")
        destination_fragment = try(c.value.fragment, "")
        query_string         = try(c.value.query_string, "")
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

/* Rewrites URLs (no redirect) based on URI/path/file conditions */
resource "azurerm_cdn_frontdoor_rule" "rewrite_only" {
  for_each                  = { for r in var.delivery_rule_rewrites : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = try(each.value.behavior_on_match, "Continue")

  conditions {
    dynamic "request_uri_condition" {
      for_each = try(each.value.request_uri_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_file_extension_condition" {
      for_each = try(each.value.url_file_extension_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_path_condition" {
      for_each = [for c in try(each.value.url_path_conditions, []) : c]
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = compact([for v in c.value.match_values : v])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }
  }

  actions {
    dynamic "url_rewrite_action" {
      for_each = each.value.url_rewrite_actions
      iterator = c
      content {
        source_pattern          = c.value.source_pattern
        destination             = c.value.destination
        preserve_unmatched_path = try(tobool(c.value.preserve_unmatched_path), false)
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.storage_web_host,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

/* Generic custom rules for headers/cache/qs (no redirect/rewrite) */
resource "azurerm_cdn_frontdoor_rule" "custom_rules" {
  for_each                  = { for r in var.delivery_custom_rules : r.name => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = try(each.value.behavior_on_match, "Continue")

  conditions {
    dynamic "cookies_condition" {
      for_each = try(each.value.cookies_conditions, [])
      iterator = c
      content {
        cookie_name      = c.value.selector
        operator         = c.value.operator
        match_values     = try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "is_device_condition" {
      for_each = try(each.value.device_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = try(tostring(c.value.match_values), null) != null ? [c.value.match_values] : try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
      }
    }

    dynamic "http_version_condition" {
      for_each = try(each.value.http_version_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
      }
    }

    dynamic "post_args_condition" {
      for_each = try(each.value.post_arg_conditions, [])
      iterator = c
      content {
        post_args_name   = c.value.selector
        operator         = c.value.operator
        match_values     = try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "query_string_condition" {
      for_each = try(each.value.query_string_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "remote_address_condition" {
      for_each = try(each.value.remote_address_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
      }
    }

    dynamic "request_body_condition" {
      for_each = try(each.value.request_body_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "request_header_condition" {
      for_each = try(each.value.request_header_conditions, [])
      iterator = c
      content {
        header_name      = c.value.selector
        operator         = c.value.operator
        match_values     = try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "request_method_condition" {
      for_each = try(each.value.request_method_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
      }
    }

    dynamic "request_scheme_condition" {
      for_each = try(each.value.request_scheme_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = try(tolist(c.value.match_values), [c.value.match_values])
        negate_condition = try(c.value.negate_condition, false)
      }
    }

    dynamic "request_uri_condition" {
      for_each = try(each.value.request_uri_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_file_extension_condition" {
      for_each = try(each.value.url_file_extension_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = c.value.match_values
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_filename_condition" {
      for_each = try(each.value.url_file_name_conditions, [])
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = try(c.value.match_values, [])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }

    dynamic "url_path_condition" {
      for_each = [for c in try(each.value.url_path_conditions, []) : c]
      iterator = c
      content {
        operator         = c.value.operator
        match_values     = compact([for v in c.value.match_values : trimprefix(v, "/")])
        negate_condition = try(c.value.negate_condition, false)
        transforms       = try(c.value.transforms, [])
      }
    }
  }

  actions {
    dynamic "response_header_action" {
      for_each = try(each.value.modify_response_header_actions, [])
      iterator = rha
      content {
        header_action = rha.value.action
        header_name   = rha.value.name
        value         = rha.value.value
      }
    }

    dynamic "request_header_action" {
      for_each = try(each.value.modify_request_header_actions, [])
      iterator = rqa
      content {
        header_action = rqa.value.action
        header_name   = rqa.value.name
        value         = rqa.value.value
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = try(each.value.cache_expiration_actions, [])
      iterator = c
      content {
        cache_behavior = lookup({
          "Override"     = "OverrideAlways",
          "SetIfMissing" = "OverrideIfOriginMissing",
          "BypassCache"  = "Disabled",
          "HonorOrigin"  = "HonorOrigin"
        }, c.value.behavior, "HonorOrigin")
        cache_duration = c.value.duration
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = [for ck in try(each.value.cache_key_query_string_actions, []) : ck if contains(["IgnoreQueryString", "UseQueryString"], ck.behavior)]
      iterator = ck
      content {
        query_string_caching_behavior = ck.value.behavior
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = [for ck in try(each.value.cache_key_query_string_actions, []) : ck if contains(["IncludeSpecifiedQueryStrings", "IgnoreSpecifiedQueryStrings"], ck.behavior)]
      iterator = ck
      content {
        query_string_caching_behavior = ck.value.behavior
        query_string_parameters       = length(trimspace(ck.value.parameters)) > 0 ? split(",", trimspace(ck.value.parameters)) : []
      }
    }

    dynamic "url_redirect_action" {
      for_each = length(try(each.value.url_rewrite_actions, [])) == 0 ? try(each.value.url_redirect_actions, []) : []
      iterator = c
      content {
        redirect_type        = c.value.redirect_type
        redirect_protocol    = try(c.value.protocol, null)
        destination_hostname = try(c.value.hostname, "")
        destination_path     = try(c.value.path, "")
        destination_fragment = try(c.value.fragment, "")
        query_string         = try(c.value.query_string, "")
      }
    }

    dynamic "url_rewrite_action" {
      for_each = length(try(each.value.url_redirect_actions, [])) == 0 ? try(each.value.url_rewrite_actions, []) : []
      iterator = c
      content {
        source_pattern          = c.value.source_pattern
        destination             = c.value.destination
        preserve_unmatched_path = try(tobool(c.value.preserve_unmatched_path), false)
      }
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
/* Resolves DNS zones for each configured domain */
data "azurerm_dns_zone" "zones" {
  for_each            = local.domains
  name                = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
}

/* Retrieves Key Vault certificates for apex domains */
data "azurerm_key_vault_certificate" "certs" {
  for_each     = { for k, v in local.domains : k => v if local.is_apex[k] && var.keyvault_id != null }
  name         = replace(each.key, ".", "-")
  key_vault_id = local.keyvault_id
  depends_on   = [azurerm_key_vault_access_policy.afd_policy]
}

/* Grants AFD managed identity read access to KV secrets/certs */
resource "azurerm_key_vault_access_policy" "afd_policy" {
  count                   = length(local.domains) > 0 && var.keyvault_id != null ? 1 : 0
  key_vault_id            = local.keyvault_id
  tenant_id               = var.tenant_id
  object_id               = azurerm_cdn_frontdoor_profile.this.identity[0].principal_id
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}

/* Publishes customer or managed TLS certificates to AFD */
resource "azurerm_cdn_frontdoor_secret" "cert_secrets" {
  for_each                 = data.azurerm_key_vault_certificate.certs
  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.versionless_id
    }
  }
}

/* Creates AFD custom domains with TLS settings (managed or customer) */
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
}

#--------------------------------------------------------------------------------------------
# DNS records (only if enabled in domain config)
#--------------------------------------------------------------------------------------------
/* Creates TXT validation record for non-apex domains when needed */
resource "azurerm_dns_txt_record" "validation" {
  for_each = {
    for k, v in local.domains : k => v
    if try(v.enable_dns_records, true) && !local.is_apex[k]
  }

  name                = local.dns_txt_name[each.key]
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = try(each.value.ttl, 3600)

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token
  }

  lifecycle {
    precondition {
      condition     = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token != null && length(trimspace(azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token)) > 0
      error_message = "The validation_token for domain '${each.key}' has not been generated by Azure Front Door. A TXT record cannot be created without a token. This may be expected if the domain is already validated or does not require TXT validation."
    }
  }

  depends_on = [azurerm_cdn_frontdoor_custom_domain.this]
}

/* Points apex domains to AFD endpoint via A record */
resource "azurerm_dns_a_record" "apex" {
  for_each            = { for k, v in local.domains : k => v if local.is_apex[k] && try(v.enable_dns_records, true) }
  name                = "@"
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = try(each.value.ttl, 3600)
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.this.id
}

/* Points subdomains to AFD endpoint hostname via CNAME */
resource "azurerm_dns_cname_record" "subdomain" {
  for_each            = { for k, v in local.domains : k => v if !local.is_apex[k] && try(v.enable_dns_records, true) }
  name                = local.hostname_label[each.key]
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = try(each.value.ttl, 3600)
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name
}

############################################################
# Default Route
############################################################
/* Wires endpoint to origin group, attaches ruleset and domains */
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
    || length(var.delivery_custom_rules) > 0
    || length(var.delivery_rule_redirects) > 0
    || length(var.delivery_rule_rewrites) > 0
    || length(var.delivery_rule_request_scheme_condition) > 0
    || length(var.delivery_rule_url_path_condition_cache_expiration_action) > 0
  ) ? [azurerm_cdn_frontdoor_rule_set.this[0].id] : []

  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.storage_web_host.id]
  cdn_frontdoor_custom_domain_ids = [for d in azurerm_cdn_frontdoor_custom_domain.this : d.id]

  cache {
    query_string_caching_behavior = var.querystring_caching_behaviour
  }
}

############################################################
# Diagnostics
############################################################
/* Sends AFD profile logs and metrics to Log Analytics */
resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings_cdn_profile" {
  name                       = local.fd_diag_name
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log   { category_group = "allLogs" }
  enabled_metric{ category       = "AllMetrics" }
}
