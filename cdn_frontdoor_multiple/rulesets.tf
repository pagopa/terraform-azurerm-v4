############################################################
# Rule Sets
############################################################

resource "azurerm_cdn_frontdoor_rule_set" "rulesets" {
  for_each = local.rulesets_normalized

  name                     = each.value.actual_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
}

############################################################
# Rules
############################################################

resource "azurerm_cdn_frontdoor_rule" "rules" {
  for_each = local.rules_flattened

  name                      = each.value.rule_name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rulesets[each.value.ruleset_key].id
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  # ============================================================
  # Conditions Block
  # ============================================================
  dynamic "conditions" {
    for_each = (
      each.value.condition != null ||
      length(try(each.value.conditions, [])) > 0
    ) ? [1] : []

    content {
      # Single condition
      dynamic "request_scheme_condition" {
        for_each = try(each.value.condition.type, null) == "request_scheme" ? [each.value.condition] : []
        content {
          operator         = request_scheme_condition.value.operator
          match_values     = request_scheme_condition.value.match_values
          negate_condition = try(request_scheme_condition.value.negate, false)
        }
      }

      dynamic "url_path_condition" {
        for_each = try(each.value.condition.type, null) == "url_path" ? [each.value.condition] : []
        content {
          operator         = url_path_condition.value.operator
          match_values     = [for v in url_path_condition.value.match_values : trimprefix(v, "/")]
          negate_condition = try(url_path_condition.value.negate, false)
          transforms       = try(url_path_condition.value.transforms, [])
        }
      }

      dynamic "request_uri_condition" {
        for_each = try(each.value.condition.type, null) == "request_uri" ? [each.value.condition] : []
        content {
          operator         = request_uri_condition.value.operator
          match_values     = request_uri_condition.value.match_values
          negate_condition = try(request_uri_condition.value.negate, false)
          transforms       = try(request_uri_condition.value.transforms, [])
        }
      }

      dynamic "request_method_condition" {
        for_each = try(each.value.condition.type, null) == "request_method" ? [each.value.condition] : []
        content {
          operator         = request_method_condition.value.operator
          match_values     = request_method_condition.value.match_values
          negate_condition = try(request_method_condition.value.negate, false)
        }
      }

      dynamic "url_file_extension_condition" {
        for_each = try(each.value.condition.type, null) == "url_file_extension" ? [each.value.condition] : []
        content {
          operator         = url_file_extension_condition.value.operator
          match_values     = url_file_extension_condition.value.match_values
          negate_condition = try(url_file_extension_condition.value.negate, false)
          transforms       = try(url_file_extension_condition.value.transforms, [])
        }
      }

      dynamic "url_filename_condition" {
        for_each = try(each.value.condition.type, null) == "url_filename" ? [each.value.condition] : []
        content {
          operator         = url_filename_condition.value.operator
          match_values     = try(url_filename_condition.value.match_values, [])
          negate_condition = try(url_filename_condition.value.negate, false)
          transforms       = try(url_filename_condition.value.transforms, [])
        }
      }

      dynamic "query_string_condition" {
        for_each = try(each.value.condition.type, null) == "query_string" ? [each.value.condition] : []
        content {
          operator         = query_string_condition.value.operator
          match_values     = try(query_string_condition.value.match_values, [])
          negate_condition = try(query_string_condition.value.negate, false)
          transforms       = try(query_string_condition.value.transforms, [])
        }
      }

      dynamic "request_header_condition" {
        for_each = try(each.value.condition.type, null) == "request_header" ? [each.value.condition] : []
        content {
          header_name      = try(request_header_condition.value.selector, "")
          operator         = request_header_condition.value.operator
          match_values     = try(request_header_condition.value.match_values, [])
          negate_condition = try(request_header_condition.value.negate, false)
          transforms       = try(request_header_condition.value.transforms, [])
        }
      }

      dynamic "cookies_condition" {
        for_each = try(each.value.condition.type, null) == "cookies" ? [each.value.condition] : []
        content {
          cookie_name      = try(cookies_condition.value.selector, "")
          operator         = cookies_condition.value.operator
          match_values     = try(cookies_condition.value.match_values, [])
          negate_condition = try(cookies_condition.value.negate, false)
          transforms       = try(cookies_condition.value.transforms, [])
        }
      }

      dynamic "remote_address_condition" {
        for_each = try(each.value.condition.type, null) == "remote_address" ? [each.value.condition] : []
        content {
          operator         = remote_address_condition.value.operator
          match_values     = try(remote_address_condition.value.match_values, [])
          negate_condition = try(remote_address_condition.value.negate, false)
        }
      }

      dynamic "http_version_condition" {
        for_each = try(each.value.condition.type, null) == "http_version" ? [each.value.condition] : []
        content {
          operator         = http_version_condition.value.operator
          match_values     = http_version_condition.value.match_values
          negate_condition = try(http_version_condition.value.negate, false)
        }
      }

      dynamic "is_device_condition" {
        for_each = try(each.value.condition.type, null) == "device" ? [each.value.condition] : []
        content {
          operator         = is_device_condition.value.operator
          match_values     = [is_device_condition.value.match_values[0]]
          negate_condition = try(is_device_condition.value.negate, false)
        }
      }

      dynamic "post_args_condition" {
        for_each = try(each.value.condition.type, null) == "post_args" ? [each.value.condition] : []
        content {
          post_args_name   = try(post_args_condition.value.selector, "")
          operator         = post_args_condition.value.operator
          match_values     = try(post_args_condition.value.match_values, [])
          negate_condition = try(post_args_condition.value.negate, false)
          transforms       = try(post_args_condition.value.transforms, [])
        }
      }

      # Multiple conditions
      dynamic "request_scheme_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "request_scheme"]
        content {
          operator         = request_scheme_condition.value.operator
          match_values     = request_scheme_condition.value.match_values
          negate_condition = try(request_scheme_condition.value.negate, false)
        }
      }

      dynamic "url_path_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "url_path"]
        content {
          operator         = url_path_condition.value.operator
          match_values     = [for v in url_path_condition.value.match_values : trimprefix(v, "/")]
          negate_condition = try(url_path_condition.value.negate, false)
          transforms       = try(url_path_condition.value.transforms, [])
        }
      }

      dynamic "request_uri_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "request_uri"]
        content {
          operator         = request_uri_condition.value.operator
          match_values     = request_uri_condition.value.match_values
          negate_condition = try(request_uri_condition.value.negate, false)
          transforms       = try(request_uri_condition.value.transforms, [])
        }
      }

      dynamic "request_method_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "request_method"]
        content {
          operator         = request_method_condition.value.operator
          match_values     = request_method_condition.value.match_values
          negate_condition = try(request_method_condition.value.negate, false)
        }
      }

      dynamic "url_file_extension_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "url_file_extension"]
        content {
          operator         = url_file_extension_condition.value.operator
          match_values     = url_file_extension_condition.value.match_values
          negate_condition = try(url_file_extension_condition.value.negate, false)
          transforms       = try(url_file_extension_condition.value.transforms, [])
        }
      }

      dynamic "url_filename_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "url_filename"]
        content {
          operator         = url_filename_condition.value.operator
          match_values     = try(url_filename_condition.value.match_values, [])
          negate_condition = try(url_filename_condition.value.negate, false)
          transforms       = try(url_filename_condition.value.transforms, [])
        }
      }

      dynamic "query_string_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "query_string"]
        content {
          operator         = query_string_condition.value.operator
          match_values     = try(query_string_condition.value.match_values, [])
          negate_condition = try(query_string_condition.value.negate, false)
          transforms       = try(query_string_condition.value.transforms, [])
        }
      }

      dynamic "request_header_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "request_header"]
        content {
          header_name      = request_header_condition.value.selector
          operator         = request_header_condition.value.operator
          match_values     = try(request_header_condition.value.match_values, [])
          negate_condition = try(request_header_condition.value.negate, false)
          transforms       = try(request_header_condition.value.transforms, [])
        }
      }

      dynamic "cookies_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "cookies"]
        content {
          cookie_name      = cookies_condition.value.selector
          operator         = cookies_condition.value.operator
          match_values     = try(cookies_condition.value.match_values, [])
          negate_condition = try(cookies_condition.value.negate, false)
          transforms       = try(cookies_condition.value.transforms, [])
        }
      }

      dynamic "remote_address_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "remote_address"]
        content {
          operator         = remote_address_condition.value.operator
          match_values     = try(remote_address_condition.value.match_values, [])
          negate_condition = try(remote_address_condition.value.negate, false)
        }
      }

      dynamic "http_version_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "http_version"]
        content {
          operator         = http_version_condition.value.operator
          match_values     = http_version_condition.value.match_values
          negate_condition = try(http_version_condition.value.negate, false)
        }
      }

      dynamic "is_device_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "device"]
        content {
          operator         = is_device_condition.value.operator
          match_values     = [is_device_condition.value.match_values[0]]
          negate_condition = try(is_device_condition.value.negate, false)
        }
      }

      dynamic "post_args_condition" {
        for_each = [for c in try(each.value.conditions, []) : c if c.type == "post_args"]
        content {
          post_args_name   = post_args_condition.value.selector
          operator         = post_args_condition.value.operator
          match_values     = try(post_args_condition.value.match_values, [])
          negate_condition = try(post_args_condition.value.negate, false)
          transforms       = try(post_args_condition.value.transforms, [])
        }
      }
    }
  }

  # ============================================================
  # Actions Block
  # ============================================================
  dynamic "actions" {
    for_each = [each.value.actions]
    content {
      # Redirect
      dynamic "url_redirect_action" {
        for_each = [for a in actions.value : a if a.type == "redirect"]
        content {
          redirect_type        = url_redirect_action.value.redirect_type
          redirect_protocol    = try(url_redirect_action.value.protocol, null)
          destination_hostname = try(url_redirect_action.value.hostname, "")
          destination_path     = try(url_redirect_action.value.path, "")
          destination_fragment = try(url_redirect_action.value.fragment, "")
          query_string         = try(url_redirect_action.value.query_string, "")
        }
      }

      # Rewrite
      dynamic "url_rewrite_action" {
        for_each = [for a in actions.value : a if a.type == "rewrite"]
        content {
          source_pattern          = url_rewrite_action.value.source_pattern
          destination             = url_rewrite_action.value.destination
          preserve_unmatched_path = try(tobool(url_rewrite_action.value.preserve_unmatched_path), false)
        }
      }

      # Cache
      dynamic "route_configuration_override_action" {
        for_each = [for a in actions.value : a if a.type == "cache"]
        content {
          cache_behavior = lookup({
            "Override"     = "OverrideAlways"
            "SetIfMissing" = "OverrideIfOriginMissing"
            "Disabled"     = "Disabled"
            "HonorOrigin"  = "HonorOrigin"
          }, try(route_configuration_override_action.value.behavior, "HonorOrigin"), "HonorOrigin")

          cache_duration = try(route_configuration_override_action.value.duration, null)

          query_string_caching_behavior = try(route_configuration_override_action.value.query_string_behavior, null)

          query_string_parameters = (
            contains(
              ["IncludeSpecifiedQueryStrings", "IgnoreSpecifiedQueryStrings"],
              coalesce(try(route_configuration_override_action.value.query_string_behavior, null), "none")
            )
            && length(trimspace(try(route_configuration_override_action.value.query_string_params, null) == null ? "" : route_configuration_override_action.value.query_string_params)) > 0
          ) ? split(",", trimspace(try(route_configuration_override_action.value.query_string_params, null) == null ? "" : route_configuration_override_action.value.query_string_params)) : null
        }
      }

      # Request header
      dynamic "request_header_action" {
        for_each = [for a in actions.value : a if a.type == "request_header"]
        content {
          header_action = request_header_action.value.header_action
          header_name   = request_header_action.value.header_name
          value         = request_header_action.value.value
        }
      }

      # Response header
      dynamic "response_header_action" {
        for_each = [for a in actions.value : a if a.type == "response_header"]
        content {
          header_action = response_header_action.value.header_action
          header_name   = response_header_action.value.header_name
          value         = response_header_action.value.value
        }
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.origins,
    azurerm_cdn_frontdoor_origin_group.origin_groups
  ]
}
