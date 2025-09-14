output "workload_identity_service_account_name" {
  description = "Service Account name created by workload identity configuration"
  value       = try(module.argocd_workload_identity_configuration[0].workload_identity_service_account_name, null)
}

output "workload_identity_client_id" {
  description = "Client ID created by workload identity configuration"
  value       = try(module.argocd_workload_identity_configuration[0].workload_identity_client_id, null)
}

