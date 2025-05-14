variable "prefix" {
  type = string
  validation {
    condition = (
      length(var.prefix) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type = string
}

variable "name" {
  type        = string
  description = "(Required) The name which should be used for this PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
}

variable "location" {
  type        = string
  description = "(Required) The Azure Region where the PostgreSQL Flexible Server should exist."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where the PostgreSQL Flexible Server should exist."
}


variable "idh_resource" {
  type        = string
  description = "(Required) The name od IDH resource key to be created."
}

#
# Network
#


variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the private dns zone to create the PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
}

variable "delegated_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the virtual network subnet to create the PostgreSQL Flexible Server. The provided subnet should not have any other resource deployed in it and this subnet will be delegated to the PostgreSQL Flexible Server, if not already delegated."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether this PostgreSQL Flexible Server is publicly accessible."
}

#
# ♊️ High Availability
#


variable "standby_availability_zone" {
  type        = number
  default     = null
  description = "(Optional) Specifies the Availability Zone in which the standby Flexible Server should be located."
}



#
# Administration
#


variable "customer_managed_key_enabled" {
  type        = bool
  description = "enable customer_managed_key"
  default     = false
}

variable "customer_managed_key_kv_key_id" {
  type        = string
  description = "The ID of the Key Vault Key"
  default     = null
}

variable "administrator_login" {
  type        = string
  description = "Flexible PostgreSql server administrator_login"
}

variable "administrator_password" {
  type        = string
  description = "Flexible PostgreSql server administrator_password"
}

#
# Backup
#



variable "zone" {
  type        = number
  description = "(Optional) Specifies the Availability Zone in which the PostgreSQL Flexible Server should be located."
  default     = null
}

variable "primary_user_assigned_identity_id" {
  type        = string
  description = "Manages a User Assigned Identity"
  default     = null
}

#
# Monitoring & Alert
#
variable "custom_metric_alerts" {
  default = null

  description = <<EOD
  Map of name = criteria objects
  EOD

  type = map(object({
    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]
    aggregation = string
    metric_name = string
    # "Insights.Container/pods" "Insights.Container/nodes"
    metric_namespace = string
    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]
    operator  = string
    threshold = number
    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H
    frequency = string
    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.
    window_size = string
    # severity: The severity of this Metric Alert. Possible values are 0, 1, 2, 3 and 4. Defaults to 3.
    severity = number
  }))
}


variable "alerts_enabled" {
  type        = bool
  default     = true
  description = "Should Metrics Alert be enabled?"
}

variable "alert_action" {
  description = "The ID of the Action Group and optional map of custom string properties to include with the post webhook operation."
  type = set(object(
    {
      action_group_id    = string
      webhook_properties = map(string)
    }
  ))
  default = []
}

variable "diagnostic_settings_enabled" {
  type        = bool
  default     = true
  description = "Is diagnostic settings enabled?"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent."
}

variable "diagnostic_setting_destination_storage_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Storage Account where logs should be sent. Changing this forces a new resource to be created."
}

variable "tags" {
  type = map(any)
}

variable "private_dns_registration" {
  type        = bool
  default     = false
  description = "(Optional) If true, creates a cname record for the newly created postgreSQL db fqdn into the provided private dns zone"
}

variable "private_dns_zone_name" {
  type        = string
  default     = null
  description = "(Optional) if 'private_dns_registration' is true, defines the private dns zone name in which the server fqdn should be registered"
}

variable "private_dns_zone_rg_name" {
  type        = string
  default     = null
  description = "(Optional) if 'private_dns_registration' is true, defines the private dns zone resource group name of the dns zone in which the server fqdn should be registered"
}

variable "private_dns_record_cname" {
  type        = string
  default     = null
  description = "(Optional) if 'private_dns_registration' is true, defines the private dns CNAME used to register this server FQDN"
}

variable "private_dns_cname_record_ttl" {
  type        = number
  default     = 300
  description = "(Optional) if 'private_dns_registration' is true, defines the record TTL"
}

variable "auto_grow_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is the storage auto grow for PostgreSQL Flexible Server enabled? Defaults to false"
}

variable "databases" {
  type = list(string)
  description = "(Optional) List of database names to be created"
  default     = []
}

variable "geo_replication" {
  type = object({
    enabled = bool
    name = string
    subnet_id = string
    location = string
    private_dns_registration_ve = bool
    private_dns_name = string
    private_dns_zone_name = string
    private_dns_rg = string
  })
  default = {
    enabled = false
    name = ""
    subnet_id = ""
    location = ""
    private_dns_registration_ve = false
    private_dns_name = ""
    private_dns_zone_name = ""
    private_dns_rg = ""
  }
}
