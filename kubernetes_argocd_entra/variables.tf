variable "prefix" {
  description = "Project prefix (e.g., cstar)"
  type        = string
}


variable "argocd_hostname" {
  description = "FQDN used by ArgoCD (internal/external)"
  type        = string
}

variable "entra_app_owners_object_ids" {
  description = "Object IDs for Entra app owners"
  type        = list(string)
}

variable "entra_group_display_names" {
  description = "Entra group display names to assign to the Enterprise App"
  type        = list(string)
  default     = []
}

variable "aks_name" {
  description = "AKS cluster name (to resolve OIDC issuer)"
  type        = string
}

variable "aks_resource_group_name" {
  description = "AKS cluster resource group name"
  type        = string
}

variable "argocd_namespace" {
  description = "Kubernetes namespace of ArgoCD server"
  type        = string
  default     = "argocd"
}

variable "argocd_service_account_name" {
  description = "ServiceAccount name used by ArgoCD server"
  type        = string
  default     = "argocd-server"
}

variable "key_vault_id" {
  description = "Key Vault ID where to store outputs"
  type        = string
}

variable "kv_secret_app_client_id_name" {
  description = "Key Vault secret name for the ArgoCD Entra app client id"
  type        = string
  default     = "argocd-entra-app-workload-client-id"
}

variable "kv_secret_service_account_name" {
  description = "Key Vault secret name for the ArgoCD service account name"
  type        = string
  default     = "argocd-entra-app-workload-service-account-name"
}
