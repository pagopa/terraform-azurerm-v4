data "azurerm_subnet" "subnet" {
  for_each = { for subnet in local.subnet_names : "${subnet.name}-${subnet.vnet_name}" => subnet }

  name                 = each.value.name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.rg_name
}


data "azurerm_log_analytics_workspace" "analytics_workspace" {
  count               = var.flow_logs != null ? 1 : 0
  name                = var.flow_logs.traffic_analytics_law_name
  resource_group_name = var.flow_logs.traffic_analytics_law_rg
}
