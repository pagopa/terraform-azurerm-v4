variable "namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  type        = string
}

variable "argocd_helm_release_version" {
  description = "ArgoCD helm chart release version"
  type        = string
  default     = "8.3.7" #3.1.5+
}

variable "argocd_application_namespaces" {
  description = "Namespaces where ArgoCD can create applications"
  type        = list(string)
}

variable "argocd_force_reinstall_version" {
  description = "Change this value to force the reinstallation of ArgoCD"
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Azure tenant id"
  type        = string
}

variable "entra_app_client_id" {
  description = "Workload identity application client id"
  type        = string
}

variable "argocd_internal_url" {
  description = "Internal DNS hostname for ArgoCD"
  type        = string
}

variable "ingress_tls_secret_name" {
  description = "TLS secret name for ArgoCD ingress"
  type        = string
  default     = null
}

variable "kv_id" {
  description = "Key Vault id"
  type        = string
}

variable "aks_name" {
  description = "AKS cluster name"
  type        = string
}

variable "aks_resource_group_name" {
  description = "AKS resource group name"
  type        = string
}

variable "workload_identity_resource_group_name" {
  description = "Resource group for workload identity resources"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "internal_dns_zone_name" {
  description = "Internal Private DNS Zone name"
  type        = string
}

variable "internal_dns_zone_resource_group_name" {
  description = "Resource group name for internal Private DNS Zone"
  type        = string
}

variable "ingress_load_balancer_ip" {
  description = "Ingress Controller Load Balancer IP"
  type        = string
}

variable "dns_record_name_for_ingress" {
  description = "DNS A record name for the ArgoCD ingress"
  type        = string
  default     = "argocd"
}

variable "admin_password" {
  description = "Admin password (plain). If null, a random one is generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_store_admin_password" {
  description = "Enable storing of ArgoCD admin password in Key Vault"
  type        = bool
  default     = true
}

# Optional Entra group object IDs; default to empty
variable "entra_admin_group_object_ids" {
  description = "Azure Entra ID admin group object IDs"
  type        = list(string)
  default     = []
}

variable "entra_developer_group_object_ids" {
  description = "Azure Entra ID developer group object IDs"
  type        = list(string)
  default     = []
}

variable "entra_reader_group_object_ids" {
  description = "Azure Entra ID reader group object IDs"
  type        = list(string)
  default     = []
}

variable "entra_guest_group_object_ids" {
  description = "Azure Entra ID guest group object IDs"
  type        = list(string)
  default     = []
}

# Enable flags per sub-resource (default true)
variable "enable_helm_release" {
  description = "Enable ArgoCD helm release"
  type        = bool
  default     = true
}

variable "enable_change_admin_password" {
  description = "Enable patching of ArgoCD admin password"
  type        = bool
  default     = true
}

variable "enable_restart_argocd_server" {
  description = "Enable restart of ArgoCD server deployment"
  type        = bool
  default     = true
}

variable "enable_store_admin_username" {
  description = "Enable storing of ArgoCD admin username in Key Vault"
  type        = bool
  default     = true
}

variable "enable_workload_identity_init" {
  description = "Enable workload identity init module"
  type        = bool
  default     = true
}

variable "enable_workload_identity_configuration" {
  description = "Enable workload identity configuration module"
  type        = bool
  default     = true
}

variable "enable_private_dns_a_record" {
  description = "Enable creation of Private DNS A record for ArgoCD"
  type        = bool
  default     = true
}

variable "tags" {
  type = map(any)
  description = "A map of tags to assign to the resource."
  default = {}
}
