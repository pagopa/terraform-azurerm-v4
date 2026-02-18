output "id" {
  value       = local.created_law.id
  description = "The ID of the Log Analytics Workspace."
}

output "name" {
  value       = local.created_law.name
  description = "The name of the Log Analytics Workspace."
}

output "resource_group" {
  value       = local.created_law.resource_group_name
  description = "The resource group of the Log Analytics Workspace."
}

output "application_insights_id" {
  value       = var.application_insights_id != null ? var.application_insights_id : (length(azurerm_application_insights.application_insights) > 0 ? azurerm_application_insights.application_insights[0].id : null)
  description = "The ID of the Application Insights resource."
}

output "application_insights_instrumentation_key" {
  value       = length(azurerm_application_insights.application_insights) > 0 ? azurerm_application_insights.application_insights[0].instrumentation_key : (length(data.azurerm_application_insights.application_insights) > 0 ? data.azurerm_application_insights.application_insights[0].instrumentation_key : null)
  description = "The Instrumentation Key of the Application Insights resource."
  sensitive   = true
}

output "application_insights_app_id" {
  value       = length(azurerm_application_insights.application_insights) > 0 ? azurerm_application_insights.application_insights[0].app_id : (length(data.azurerm_application_insights.application_insights) > 0 ? data.azurerm_application_insights.application_insights[0].app_id : null)
  description = "The App ID of the Application Insights resource."
}
