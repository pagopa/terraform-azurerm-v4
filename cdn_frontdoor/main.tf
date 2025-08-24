############################################################
# Locals (naming, helpers)
############################################################
locals {
  name_prefix          = var.cdn_prefix_name
  cdn_location         = coalesce(var.cdn_location, var.location)
  storage_account_name = var.storage_account_name != null ? replace(var.storage_account_name, "-", "") : replace("${local.name_prefix}-sa", "-", "")

  # DNS helpers computed only when custom domain is enabled
  is_apex        = var.enable_custom_domain ? var.hostname == var.dns_zone_name : false
  hostname_label = var.enable_custom_domain ? (local.is_apex ? "" : trimsuffix(replace(var.hostname, var.dns_zone_name, ""), ".")) : ""
  dns_txt_name   = var.enable_custom_domain ? (local.hostname_label != "" ? "_dnsauth.${local.hostname_label}" : "_dnsauth") : ""

  # Naming
  fd_profile_name   = "${local.name_prefix}-cdn-profile"
  fd_endpoint_name  = "${local.name_prefix}-cdn-endpoint"
  fd_origin_group   = "origin-group"
  fd_origin_primary = "origin-group-primary"
  fd_route_default  = "route-default"
  fd_ruleset_global = replace("ruleset-global", "-", "")
  fd_rule_global    = replace("rule-global", "-", "")
  fd_diag_name      = "tf-diagnostics"
  fd_secret_name    = "secret-certificate"
  fd_customdom_name = var.enable_custom_domain ? replace(var.hostname, ".", "-") : ""

  # Certificate helpers
  keyvault_id        = var.keyvault_id
  certificate_name   = var.enable_custom_domain ? replace(var.hostname, ".", "-") : ""
  use_kv_certificate = var.enable_custom_domain ? (var.dns_zone_name == var.hostname || var.custom_hostname_kv_enabled) : false
}

############################################################
# Storage Account (static website)
############################################################
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
      match_values     = [for v in each.value.match_values : trimprefix(v, "/")] # no leading '/'
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
# Goal: apply SPA/root rewrites without changing input schema
# Context: url_path_condition disallows leading '/'; guard root "/"
# Strategy:
# 1) Pass-through request_uri_condition if provided.
# 2) Convert url_path_condition == "/" into request_uri_condition == "/".
# 3) Publish remaining url_path_condition stripping the leading '/'.
# 4) Keep var.delivery_rule_rewrite schema unchanged.
# Typical use-cases:
# - Root SPA:        "/"  → "/app/index.html"
# - SPA prefix:      "/portal/" → "/portal/index.html"
# - Extension-less:  no ext → fallback to index.html
# =============================================================
resource "azurerm_cdn_frontdoor_rule" "rewrite_only" {
  for_each                  = { for r in var.delivery_rule_rewrite : r.order => r }
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[0].id
  order                     = each.value.order
  behavior_on_match         = "Continue"

  # -----------------------------------------------------------
  # CONDITIONS
  #   - request_uri_condition (pass-through):
  #       If the caller already provided conditions on the full URI, publish
  #       them as-is (leading slash allowed). Useful for root "/", regex, or
  #       full-path matching (query excluded).
  #   - request_uri_condition (auto-converted from url_path == "/"):
  #       Intercept ONLY `url_path_condition` entries whose value is exactly
  #       "/", and convert them to `request_uri_condition` with match "/".
  #   - url_path_condition (normal entries):
  #       Publish after stripping the leading slash; skip empty results.
  #       Example: ["/portal/", "/app"] → ["portal/", "app"].
  #   - url_file_extension_condition: pass-through (e.g., “no extension”).
  # -----------------------------------------------------------
  conditions {
    # 1) pass-through of request_uri_condition
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

    # 2) AUTO-CONVERSION: url_path_condition == "/" → request_uri_condition == "/"
    #    Reason: url_path does not allow a leading slash; `"/"` would become "".
    #    This avoids 400 without changing the variable schema.
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

    # 3) normal url_path values after trimming leading '/'
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

    # 4) optional extension filters
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

  # -----------------------------------------------------------
  # ACTIONS — URL REWRITE
  #  - source_pattern: what to match (e.g., "/" or "/portal/")
  #  - destination:    where to rewrite (e.g., "/portal/index.html")
  #  - preserve_unmatched_path: false for classic SPA patterns
  #    Examples:
  #    - Root → SPA index:    "/" → "/portale-enti/index.html"
  #    - SPA prefix:          "/portal/" → "/portal/index.html"
  # -----------------------------------------------------------
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

# -------------------------------------------------------------------
# Generic custom rules (conditions superset)
#   - headers
#   - cache/qs override
#   (No redirect/rewrite here per provider constraints)
# -------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_rule" "custom" {
  for_each                  = { for r in var.delivery_rule : r.name => r }
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

    dynamic "request_uri_condition" {
      for_each = flatten([
        for c in try(each.value.url_path_conditions, []) : [
          for v in try(c.match_values, []) : {
            operator         = c.operator
            match_value      = v
            negate_condition = c.negate_condition
            transforms       = try(c.transforms, [])
          } if trimspace(v) == "/"
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
      for_each = [
        for c in try(each.value.url_path_conditions, []) :
        c if length(compact([for v in try(c.match_values, []) : trimprefix(v, "/")])) > 0
      ]
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
          "Override"     = "OverrideAlways"
          "SetIfMissing" = "OverrideIfOriginMissing"
          "BypassCache"  = "Disabled"
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

    # Mutual exclusion: se è presente url_redirect_actions, non pubblichiamo rewrite
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

    # Mutual exclusion: se è presente url_redirect_actions, rewrite resta vuoto
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
  cdn_frontdoor_custom_domain_ids = var.enable_custom_domain ? [azurerm_cdn_frontdoor_custom_domain.this[0].id] : []

  cache {
    query_string_caching_behavior = var.querystring_caching_behaviour
  }

}

############################################################
# 🌐 Custom domain + TLS (managed or KV) — conditional
############################################################
# Entire block is skipped when enable_custom_domain = false.
# Also skips DNS data source and records in that case.

data "azurerm_dns_zone" "this" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_key_vault_certificate" "custom_domain" {
  count        = var.enable_custom_domain && local.use_kv_certificate ? 1 : 0
  name         = local.certificate_name
  key_vault_id = local.keyvault_id
}

resource "azurerm_cdn_frontdoor_secret" "this" {
  count                    = var.enable_custom_domain && local.use_kv_certificate ? 1 : 0
  name                     = local.fd_secret_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  secret {
    customer_certificate {
      key_vault_certificate_id = data.azurerm_key_vault_certificate.custom_domain[0].versionless_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  count                    = var.enable_custom_domain ? 1 : 0
  name                     = local.fd_customdom_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = var.enable_custom_domain ? data.azurerm_dns_zone.this[0].id : null
  host_name                = var.hostname

  tls {
    certificate_type        = local.use_kv_certificate ? "CustomerCertificate" : "ManagedCertificate"
    cdn_frontdoor_secret_id = var.enable_custom_domain && local.use_kv_certificate ? azurerm_cdn_frontdoor_secret.this[0].id : null
  }
}

resource "azurerm_dns_txt_record" "domain_validation" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = local.dns_txt_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600

  record { value = azurerm_cdn_frontdoor_custom_domain.this[0].validation_token }
}

############################################################
# DNS records (Apex A-record or subdomain CNAME) — conditional
############################################################
resource "azurerm_dns_a_record" "apex_hostname" {
  count               = var.enable_custom_domain && local.is_apex && var.create_dns_record ? 1 : 0
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.this.id
}

resource "azurerm_dns_cname_record" "hostname" {
  count               = var.enable_custom_domain && !local.is_apex && var.create_dns_record ? 1 : 0
  name                = local.hostname_label
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name
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

############################################################
# Key Vault Access Policy for AFD SP (if using KV cert) — conditional
############################################################
resource "azurerm_key_vault_access_policy" "azure_cdn_frontdoor_policy" {
  count = var.enable_custom_domain && var.custom_hostname_kv_enabled ? 1 : 0

  key_vault_id = local.keyvault_id
  tenant_id    = var.tenant_id
  object_id    = azurerm_cdn_frontdoor_profile.this.identity[0].principal_id

  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}
