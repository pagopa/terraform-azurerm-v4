
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.law_sku
  retention_in_days   = var.law_retention_in_days
  daily_quota_gb      = var.law_daily_quota_gb

  internet_query_enabled     = var.law_internet_query_enabled
  internet_ingestion_enabled = var.law_internet_ingestion_enabled

  tags = var.tags

  lifecycle {
    ignore_changes = [
      sku
    ]
  }
}

# Application insights
resource "azurerm_application_insights" "application_insights" {
  count               = var.create_application_insights && var.application_insights_id == null ? 1 : 0
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = coalesce(var.application_insights_application_type, "other")
  retention_in_days   = var.law_retention_in_days

  daily_data_cap_in_gb                  = var.application_insights_daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.application_insights_daily_data_cap_notifications_disabled

  disable_ip_masking = var.application_insights_disable_ip_masking

  local_authentication_disabled = var.application_insights_local_authentication_disabled

  internet_query_enabled     = var.law_internet_query_enabled
  internet_ingestion_enabled = var.law_internet_ingestion_enabled

  workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  tags = var.tags
}

data "azurerm_application_insights" "application_insights" {
  count               = var.application_insights_id != null && var.application_insights_name != null ? 1 : 0
  name                = var.application_insights_name
  resource_group_name = coalesce(var.application_insights_resource_group_name, var.resource_group_name)
}

resource "azurerm_log_analytics_workspace_table" "log_analytics_tables" {
  for_each = var.log_analytics_workspace_tables

  name                    = each.key
  workspace_id            = azurerm_log_analytics_workspace.log_analytics_workspace.id
  retention_in_days       = each.value.retention_in_days
  total_retention_in_days = each.value.total_retention_in_days
}

resource "azurerm_private_endpoint" "private_endpoint" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
  }

  private_dns_zone_group {
    name                 = "${var.name}-pdzg"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}