variable "storage_account_resource_group_name" {
  type        = string
  description = "(Required) Name of the resource group in which the backup storage account is located"
}

variable "aks_cluster_name" {
  type        = string
  description = "(Required) Name of the aks cluster on which Velero will be installed"
}

variable "aks_cluster_rg" {
  type        = string
  description = "(Required) AKS cluster resource group name"
}

variable "subscription_id" {
  type        = string
  description = "(Required) ID of the subscription"
}

variable "plugin_version" {
  type        = string
  description = "(Optional) Version for the velero plugin"
  default     = "v1.10.0"
}

variable "prefix" {
  type        = string
  description = "(Required) Prefix used in the Velero dedicated resource names"
}

variable "location" {
  type        = string
  description = "(Required) Resource location"
}

variable "storage_account_private_dns_zone_id" {
  type        = string
  description = "(Optional) Storage account private dns zone id, used in the private endpoint creation"
  default     = null
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "(Optional) Subnet id where to create the private endpoint for backups storage account"
  default     = null
}

variable "use_storage_private_endpoint" {
  type        = bool
  description = "(Optional) Whether to make the storage account private and use a private endpoint to connect"
  default     = true
}

variable "workload_identity_name" {
  type        = string
  description = "(Required) The full name for the user assigned identity and Workload identity. Changing this forces a new identity to be created."
}

variable "workload_identity_resource_group_name" {
  type        = string
  description = "(Required) Specifies the name of the Resource Group within which this User Assigned Identity should exist. Changing this forces a new User Assigned Identity to be created."
}

variable "storage_account_tier" {
  type        = string
  description = "(Optional) Tier used for the backup storage account"
  default     = "Standard"
}

variable "storage_account_replication_type" {
  type        = string
  description = "(Optional) Replication type used for the backup storage account"
  default     = "ZRS"
}

variable "storage_account_kind" {
  type        = string
  default     = "StorageV2"
  description = "(Optional) Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Defaults to StorageV2"
}

variable "sa_backup_retention_days" {
  type        = number
  description = "(Optional) number of days for which the storage account is available for point in time recovery"
  default     = 0
}

variable "enable_sa_backup" {
  type        = bool
  description = "(Optional) enables storage account point in time recovery"
  default     = false
}

variable "advanced_threat_protection" {
  type        = string
  description = "(Optional) Enabled azurerm_advanced_threat_protection resource, Default true"
  default     = true
}

variable "enable_low_availability_alert" {
  type        = string
  description = "(Optional) Enable the Low Availability alert. Default is true"
  default     = true
}

variable "key_vault_id" {
  type        = any
  description = "(Required) Specifies the id of the Key Vault resource. Changing this forces a new resource to be created."
}

variable "namespace_name" {
  type        = string
  description = "(Optional) The namespace name where to deploy the velero resources. It should already exist"
  default     = "velero"
}

variable "tags" {
  type = map(any)
}
