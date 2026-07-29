output "resource_group_name" {
  description = "Nome del resource group creato per l'ACR di backup."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "ID del resource group creato per l'ACR di backup."
  value       = azurerm_resource_group.this.id
}

output "backup_acr_id" {
  description = "Resource ID dell'ACR di backup."
  value       = module.container_registry_bck.id
}

output "backup_acr_name" {
  description = "Nome dell'ACR di backup."
  value       = module.container_registry_bck.name
}

output "backup_acr_login_server" {
  description = "Login server dell'ACR di backup."
  value       = "${module.container_registry_bck.name}.azurecr.io"
}

output "identity_id" {
  description = "Resource ID della User Assigned Identity dedicata al sync."
  value       = azurerm_user_assigned_identity.acr_sync.id
}

output "identity_principal_id" {
  description = "Principal ID della User Assigned Identity dedicata al sync."
  value       = azurerm_user_assigned_identity.acr_sync.principal_id
}

output "identity_client_id" {
  description = "Client ID della User Assigned Identity dedicata al sync."
  value       = azurerm_user_assigned_identity.acr_sync.client_id
}

output "container_app_job_id" {
  description = "Resource ID del Container App Job di sync."
  value       = azurerm_container_app_job.acr_backup_sync.id
}

output "container_app_job_name" {
  description = "Nome del Container App Job di sync."
  value       = azurerm_container_app_job.acr_backup_sync.name
}
