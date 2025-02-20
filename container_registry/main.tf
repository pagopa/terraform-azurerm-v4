resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "georeplications" {
    for_each = var.georeplications
    iterator = g

    content {
      location                  = g.value.location
      regional_endpoint_enabled = g.value.regional_endpoint_enabled
      zone_redundancy_enabled   = g.value.zone_redundancy_enabled
      tags                      = var.tags
    }
  }

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" ? var.network_rule_set : []
    iterator = n

    content {
      default_action = n.value.default_action
      ip_rule        = n.value.ip_rule
    }
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "${azurerm_container_registry.this.name}-private-endpoint-0"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_dns_zone_group {
    name                 = "${azurerm_container_registry.this.name}-private-dns-zone-group-0"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "${azurerm_container_registry.this.name}-private-service-connection-0"
    private_connection_resource_id = azurerm_container_registry.this.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = var.tags
}

### This resource is deprecated, use azure policy instead
resource "azurerm_monitor_diagnostic_setting" "this" {
  count                      = var.sec_log_analytics_workspace_id != null || var.monitor_diagnostic_setting_enabled ? 1 : 0
  name                       = "SecurityLogs"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = var.sec_log_analytics_workspace_id
  storage_account_id         = var.sec_storage_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}
