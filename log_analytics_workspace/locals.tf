locals {
  created_law = var.linked_law_enabled ? azurerm_log_analytics_workspace.linked_log_analytics_workspace[0] : azurerm_log_analytics_workspace.log_analytics_workspace[0]
}
