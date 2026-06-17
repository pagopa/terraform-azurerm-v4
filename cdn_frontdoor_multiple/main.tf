############################################################
# CDN Front Door Profile
############################################################
resource "azurerm_cdn_frontdoor_profile" "profile" {
  name                = local.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

############################################################
# CDN Front Door Endpoints
############################################################
resource "azurerm_cdn_frontdoor_endpoint" "endpoints" {
  for_each = local.endpoints_normalized

  name                     = each.value.actual_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  tags                     = var.tags
}

############################################################
# Diagnostics
############################################################
resource "azurerm_monitor_diagnostic_setting" "profile_diagnostics" {
  name                       = "tf-diagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.profile.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
