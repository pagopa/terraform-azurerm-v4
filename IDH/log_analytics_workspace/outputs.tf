
output "id" {
  value       = module.log_analytics_workspace.id
  description = "The ID of the Log Analytics Workspace."
}

output "name" {
  value       = module.log_analytics_workspace.name
  description = "The name of the Log Analytics Workspace."
}

output "resource_group" {
  value       = module.log_analytics_workspace.resource_group
  description = "The resource group of the Log Analytics Workspace."
}

output "application_insights_id" {
  value       = module.log_analytics_workspace.application_insights_id
  description = "The ID of the Application Insights resource."
}

output "application_insights_instrumentation_key" {
  value       = module.log_analytics_workspace.application_insights_instrumentation_key
  description = "The Instrumentation Key of the Application Insights resource."
  sensitive   = true
}

output "application_insights_app_id" {
  value       = module.log_analytics_workspace.application_insights_app_id
  description = "The App ID of the Application Insights resource."
}
