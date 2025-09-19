output "application_id" {
  description = "AzureAD application (client) ID"
  value       = azuread_application.argocd.client_id
}

output "application_object_id" {
  description = "AzureAD application object ID"
  value       = azuread_application.argocd.object_id
}

output "service_principal_object_id" {
  description = "Enterprise application (Service Principal) object ID"
  value       = azuread_service_principal.sp_argocd.object_id
}

