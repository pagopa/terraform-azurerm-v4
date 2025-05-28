output "id" {
  value = azurerm_logic_app_workflow.this.id
}

output "trigger_callback_url" {
  value = azurerm_logic_app_trigger_http_request.this.callback_url
}

output "resource_group_name" {
  value = data.azurerm_resource_group.this.name
}

output "location" {
  value = data.azurerm_resource_group.this.location
}

output "workflow_parameters" {
  value = azurerm_logic_app_workflow.this.workflow_parameters
}

output "principal_id" {
  value = azurerm_logic_app_workflow.this.identity[0].principal_id
}

output "name" {
  value = azurerm_logic_app_workflow.this.name
}
