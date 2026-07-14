############################################################
# Routes (Connect Endpoints → Origin Groups, apply Rules)
############################################################

resource "azurerm_cdn_frontdoor_route" "routes" {
  for_each = var.routes

  name                          = each.key
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoints[each.value.endpoint].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_groups[each.value.origin_group].id

  patterns_to_match      = each.value.patterns
  supported_protocols    = each.value.protocols
  https_redirect_enabled = each.value.https_redirect
  forwarding_protocol    = each.value.forwarding
  enabled                = each.value.enabled

  link_to_default_domain = coalesce(each.value.link_to_default_domain, length(each.value.custom_domains) == 0)

  # Attach rulesets referenced by this route
  cdn_frontdoor_rule_set_ids = local.route_rulesets[each.key]

  # Attach custom domains referenced by this route
  cdn_frontdoor_custom_domain_ids = [
    for domain_name in each.value.custom_domains :
    azurerm_cdn_frontdoor_custom_domain.domains[domain_name].id
  ]

  # Attach origins from the origin_group (includes the static-website storage origin when enabled)
  cdn_frontdoor_origin_ids = [
    for origin_key in local.origin_groups_with_storage[each.value.origin_group].members :
    azurerm_cdn_frontdoor_origin.origins[origin_key].id
  ]

  cache {
    query_string_caching_behavior = each.value.cache_behavior
  }

  depends_on = [
    azurerm_cdn_frontdoor_rule_set.rulesets,
    azurerm_cdn_frontdoor_rule.rules,
    azurerm_cdn_frontdoor_custom_domain.domains
  ]
}
