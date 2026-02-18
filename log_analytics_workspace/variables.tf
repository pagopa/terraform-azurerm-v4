
variable "name" {
  type        = string
  description = "(Required) The name which should be used for the Log Analytics Workspace."
}

variable "location" {
  type        = string
  description = "(Required) The Azure Region where the Log Analytics Workspace should exist."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where the Log Analytics Workspace should exist."
}

variable "tags" {
  type        = map(any)
  description = "(Required) A mapping of tags which should be assigned to the Resource."
}

variable "linked_law_enabled" {
  type        = bool
  default     = false
  description = "Enable or Disable linked cluster log analytics workspace."
}

variable "law_sku" {
  type        = string
  description = "Sku of the Log Analytics Workspace"
  default     = "PerGB2018"
  validation {
    condition = (
      contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "CapacityReservation", "PerGB2018"], var.law_sku)
    )
    error_message = "Valid values are: Free, PerNode, Premium, Standard, Standalone, CapacityReservation, PerGB2018."
  }
}

variable "law_retention_in_days" {
  type        = number
  description = "The workspace data retention in days"
  default     = 30
  validation {
    condition = (
      var.law_retention_in_days >= 30 && var.law_retention_in_days <= 730
    )
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "law_daily_quota_gb" {
  type        = number
  description = "The workspace daily quota for ingestion in GB."
  default     = -1
}

variable "law_internet_query_enabled" {
  type        = bool
  description = "Whether the workspace should be accessible for queries over the public internet."
  default     = true
}

variable "law_internet_ingestion_enabled" {
  type        = bool
  description = "Whether the workspace should allow ingestion over the public internet."
  default     = true
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "Whether the private endpoint should be enabled."
  default     = false
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where the private endpoint should be created."
  default     = null
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "A list of Private DNS Zone IDs for the Private Endpoint."
  default     = []
}

variable "log_analytics_workspace_tables" {
  type = map(object({
    retention_in_days       = optional(number)
    total_retention_in_days = optional(number)
  }))
  description = "A map of tables to create in the Log Analytics Workspace"
  default     = {}
}

variable "create_application_insights" {
  type        = bool
  description = "Should the Application Insights be created?"
  default     = true
  validation {
    condition = (
      var.create_application_insights && var.application_insights_id != null ? false : true
    )
    error_message = "If 'create_application_insights' is true, 'application_insights_id' must be null. If 'application_insights_id' is provided, 'create_application_insights' must be false."
  }
}

variable "application_insights_name" {
  type        = string
  description = "The name of the Application Insights. If creating, and not provided, it will be generated from the workspace name. If obtaining existing, this is required."
  default     = null
  validation {
    condition = (
      var.application_insights_id != null && var.application_insights_name == null ? false : true
    )
    error_message = "If 'application_insights_id' is provided (obtaining an existing resource), 'application_insights_name' is required."
  }
}

variable "application_insights_id" {
  type        = string
  description = "The ID of an existing Application Insights resource. If provided, no new Application Insights will be created."
  default     = null
}

variable "application_insights_resource_group_name" {
  type        = string
  description = "The Resource Group name of the existing Application Insights. If not provided, the workspace resource group will be used."
  default     = null
}

variable "application_insights_daily_data_cap_in_gb" {
  type        = number
  description = "Specifies the Application Insights component daily data cap in GB."
  default     = 100
}

variable "application_insights_daily_data_cap_notifications_disabled" {
  type        = bool
  description = "Specifies if a notification email will be send when the daily data cap is met."
  default     = false
}

variable "application_insights_disable_ip_masking" {
  type        = bool
  description = "By default the IP address of clients is masked to 0.0.0.0. If set to true, the full IP address will be stored."
  default     = false
}

variable "application_insights_local_authentication_disabled" {
  type        = bool
  description = "Disable Non-Azure AD based auth."
  default     = false
}

variable "application_insights_application_type" {
  type        = string
  description = "The Application type of Application Insights. If not provided, the other type will be used."
  default     = "other"
  validation {
    condition = (
      var.application_insights_application_type == null ? true : contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_insights_application_type)
    )
    error_message = "Valid values are: ios, java, MobileCenter, Node.JS, other, phone, store, web."
  }
}