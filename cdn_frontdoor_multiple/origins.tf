############################################################
# Origins (Backend Servers/Services)
############################################################

resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each = local.origins_normalized

  name = each.key
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_groups[
    # Find which origin_group contains this origin (storage origin included)
    [for og_key, og in local.origin_groups_with_storage : og_key if contains(og.members, each.key)][0]
  ].id

  enabled                        = each.value.enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = local.origins_normalized[each.key].actual_host_header
  certificate_name_check_enabled = true
  priority                       = each.value.priority
  weight                         = each.value.weight

  depends_on = [azurerm_cdn_frontdoor_origin_group.origin_groups]
}
