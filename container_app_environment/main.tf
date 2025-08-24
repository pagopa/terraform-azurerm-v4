resource "azurerm_container_app_environment" "container_app_environment" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs_destination           = var.log_analytics_workspace_id != null ? "log-analytics" : "azure-monitor"


  infrastructure_subnet_id       = var.subnet_id == null ? null : var.subnet_id
  zone_redundancy_enabled        = var.subnet_id == null ? null : var.zone_redundant
  internal_load_balancer_enabled = var.subnet_id == null ? null : var.internal_load_balancer

  dynamic "workload_profile" {
    for_each = var.workload_profiles != null ? var.workload_profiles : []

    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.type
      minimum_count         = workload_profile.value.min_count
      maximum_count         = workload_profile.value.max_count
    }
  }

  lifecycle {
    ignore_changes = [
      infrastructure_resource_group_name
    ]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_config.enabled ? 1 : 0

  name                = "${azurerm_container_app_environment.container_app_environment.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_config.subnet_id

  private_dns_zone_group {
    name                 = "${azurerm_container_app_environment.container_app_environment.name}-private-dns-zone-group"
    private_dns_zone_ids = var.private_endpoint_config.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "${azurerm_container_app_environment.container_app_environment.name}-private-service-connection"
    private_connection_resource_id = azurerm_container_app_environment.container_app_environment.id
    is_manual_connection           = false
    subresource_names              = ["managedEnvironments"]
  }

  tags = var.tags
}
