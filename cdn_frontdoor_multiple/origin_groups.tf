############################################################
# Origin Groups (Backend Pools with Health Checks)
############################################################

resource "azurerm_cdn_frontdoor_origin_group" "origin_groups" {
  for_each = local.origin_groups_normalized

  name                     = each.value.actual_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id

  session_affinity_enabled = false

  health_probe {
    path                = each.value.health_probe.path
    protocol            = each.value.health_probe.protocol
    request_type        = each.value.health_probe.request_type
    interval_in_seconds = each.value.health_probe.interval_in_seconds
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}
