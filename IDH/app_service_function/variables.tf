variable "product_name" {
  type        = string
  description = "(Required) prefix used to identify the platform for which the resource will be created"
  validation {
    condition = (
      length(var.product_name) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type        = string
  description = "(Required) Environment for which the resource will be created"
}

variable "idh_resource_tier" {
  type        = string
  description = "(Required) The name of IDH resource key to be created."
}

variable "name" {
  type        = string
  description = "App service name, used as prefix in resource names"
}

variable "location" {
  type = string
}

// Resource Group
variable "resource_group_name" {
  type = string
}



variable "health_check_path" {
  type        = string
  description = "(Optional) The health check path to be pinged by App Service."
  default     = null
}
variable "subnet_id" {
  type        = string
  description = "(Deprecated) Subnet id wether you want to integrate the app service to a subnet. Use 'embedded_subnet' instead"
  default     = null
}

variable "app_service_plan_name" {
  type        = string
  description = "(Required) Specifies the name of the App Service Plan component. Changing this forces a new resource to be created."
}
variable "always_on" {
  type        = bool
  description = "(Optional) Should the app be loaded at all times? Defaults to false."
  default     = false
}
variable "app_settings" {
  type    = map(string)
  default = {}
}
variable "allowed_subnet_ids" {
  type        = list(string)
  description = "(Optional) List of subnet allowed to call the appserver endpoint."
  default     = []
}

variable "allowed_ips" {
  type        = list(string)
  description = "(Optional) List of ips allowed to call the appserver endpoint."
  default     = []
}

variable "allowed_service_tags" {
  type        = list(string)
  description = "(Optional) List of service tags allowed to call the appserver endpoint."
  default     = []
}
variable "tags" {
  default = ""
}

variable "health_check_maxpingfailures" {
  type        = number
  description = "Max ping failures allowed"
  default     = null

  validation {
    condition     = var.health_check_maxpingfailures == null ? true : (var.health_check_maxpingfailures >= 2 && var.health_check_maxpingfailures <= 10)
    error_message = "Possible values are null or a number between 2 and 10"
  }
}

# Framework choice
variable "docker_image" {
  type    = string
  default = null
}
variable "docker_image_tag" {
  type    = string
  default = null
}
variable "docker_registry_url" {
  type    = string
  default = null
}
variable "docker_registry_username" {
  type    = string
  default = null
}
variable "docker_registry_password" {
  type    = string
  default = null
}
variable "dotnet_version" {
  type    = string
  default = null
}
variable "use_dotnet_isolated_runtime" {
  type    = string
  default = null
}
variable "java_version" {
  type    = string
  default = null
}
variable "node_version" {
  type    = string
  default = null
}
variable "python_version" {
  type    = string
  default = null
}
variable "powershell_core_version" {
  type    = string
  default = null
}
variable "use_custom_runtime" {
  type    = string
  default = null
}
variable "autoscale_settings" {
  type = object({
    max_capacity                       = number                 # maximum capacity for this app service
    scale_up_requests_threshold        = optional(number, null) # request count threshold which triggers scale up
    scale_down_requests_threshold      = optional(number, null) # request count threshold which triggers scale down
    scale_up_response_time_threshold   = optional(number, null) # response time threshold which triggers scale up
    scale_down_response_time_threshold = optional(number, null) # response time threshold which triggers scale down
    scale_up_cpu_threshold             = optional(number, null) # cpu threshold which triggers scale up
    scale_down_cpu_threshold           = optional(number, null) # cpu threshold which triggers scale down
  })
  default     = null
  description = "(Optional) Autoscale configuration"

  validation {
    error_message = "If scale_up_request_threshold is defined, also scale_down_request_threshold must be defined"
    condition     = (var.autoscale_settings == null) || ((var.autoscale_settings.scale_up_requests_threshold != null && var.autoscale_settings.scale_down_requests_threshold != null) || (var.autoscale_settings.scale_up_requests_threshold == null && var.autoscale_settings.scale_down_requests_threshold == null))
  }

  validation {
    error_message = "If scale_up_response_time_threshold is defined, also scale_down_response_time_threshold must be defined"
    condition     = (var.autoscale_settings == null) || ((var.autoscale_settings.scale_up_response_time_threshold != null && var.autoscale_settings.scale_down_response_time_threshold != null) || (var.autoscale_settings.scale_up_response_time_threshold == null && var.autoscale_settings.scale_down_response_time_threshold == null))
  }

  validation {
    error_message = "If scale_up_cpu_threshold is defined, also scale_down_cpu_threshold must be defined"
    condition     = (var.autoscale_settings == null) || ((var.autoscale_settings.scale_up_cpu_threshold != null && var.autoscale_settings.scale_down_cpu_threshold != null) || (var.autoscale_settings.scale_up_cpu_threshold == null && var.autoscale_settings.scale_down_cpu_threshold == null))
  }
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "(Deprecated) Subnet id where to save the private endpoint. Use 'embedded_subnet instead'"
  default     = null
}

variable "private_endpoint_dns_zone_id" {
  type        = string
  description = "(Optional) Private DNS Zone ID to link to the private endpoint"
  default     = null
}

variable "application_insights_instrumentation_key" {
  type        = string
  description = "(Required) The Instrumentation Key of an Application Insights component."
}

variable "action" {
  description = "The ID of the Action Group and optional map of custom string properties to include with the post webhook operation."
  type = set(object(
    {
      action_group_id    = string
      webhook_properties = map(string)
    }
  ))
  default = []
}

variable "app_service_logs" {
  type = object({
    disk_quota_mb         = number
    retention_period_days = number
  })
  description = "disk_quota_mb - (Optional) The amount of disk space to use for logs. Valid values are between 25 and 100. Defaults to 35. retention_period_days - (Optional) The retention period for logs in days. Valid values are between 0 and 99999.(never delete)."
  default     = null
}

variable "default_storage_enable" {
  type        = bool
  default     = true
  description = "(Optional) Enable default storage for function app. (Default: true)"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name. If null it will be 'computed'"
  default     = null
}

variable "storage_account_access_key" {
  type        = string
  description = "Storage account access key."
  default     = null
}

variable "internal_storage" {
  type = object({
    enable                     = bool
    private_endpoint_subnet_id = string
    private_dns_zone_blob_ids  = list(string)
    private_dns_zone_queue_ids = list(string)
    private_dns_zone_table_ids = list(string)
    queues                     = list(string) # Queues names
    containers                 = list(string) # Containers names
    blobs_retention_days       = number
  })

  default = {
    enable                     = false
    private_endpoint_subnet_id = "dummy"
    private_dns_zone_blob_ids  = []
    private_dns_zone_queue_ids = []
    private_dns_zone_table_ids = []
    queues                     = []
    containers                 = []
    blobs_retention_days       = 1
  }
}


variable "cors" {
  type = object({
    allowed_origins = list(string) # A list of origins which should be able to make cross-origin calls. * can be used to allow all calls.
  })
  default = null
}

variable "domain" {
  type        = string
  description = "Specifies the domain of the Function App."
  default     = null
}

variable "healthcheck_threshold" {
  type        = number
  description = "The healthcheck threshold. If metric average is under this value, the alert will be triggered. Default is 50"
  default     = 50
}

variable "pre_warmed_instance_count" {
  type        = number
  description = "The number of pre-warmed instances for this function app. Only affects apps on the Premium plan."
  default     = 1
}


variable "sticky_app_setting_names" {
  type        = list(string)
  description = "(Optional) A list of app_setting names that the Linux Function App will not swap between Slots when a swap operation is triggered"
  default     = []
}

variable "sticky_connection_string_names" {
  type        = list(string)
  description = "(Optional) A list of connection string names that the Linux Function App will not swap between Slots when a swap operation is triggered"
  default     = null
}

variable "storage_account_durable_name" {
  type        = string
  description = "Storage account name only used by the durable function. If null it will be 'computed'"
  default     = null
}

variable "embedded_subnet" {
  type = object({
    enabled      = bool
    vnet_name    = optional(string, null)
    vnet_rg_name = optional(string, null)
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the Cosmos private endpoint. When enabled, 'private_endpoint_subnet_id' must be null."
  default = {
    enabled      = false
    vnet_name    = null
    vnet_rg_name = null
  }

  validation {
    condition     = var.embedded_subnet.enabled ? var.subnet_id == null : true
    error_message = "If 'embedded_subnet' is enabled, 'subnet_id' must be null."
  }

  validation {
    condition     = var.embedded_subnet.enabled ? var.private_endpoint_subnet_id == null : true
    error_message = "If 'embedded_subnet' is enabled, 'private_endpoint_subnet_id' must be null."
  }

  validation {
    condition     = var.embedded_subnet.enabled ? (var.embedded_subnet.vnet_name != null && var.embedded_subnet.vnet_rg_name != null) : true
    error_message = "If 'embedded_subnet' is enabled, both 'vnet_name' and 'vnet_rg_name' must be provided."
  }


}


variable "embedded_nsg_configuration" {
  type = object({
    source_address_prefixes      = list(string)
    source_address_prefixes_name = string # short name for source_address_prefixes
    target_ports                 = list(string)
    protocol                     = string
  })
  description = "(Optional) NSG configuration"
  default = {
    source_address_prefixes      = ["*"]
    source_address_prefixes_name = "All"
    target_ports                 = ["*"]
    protocol                     = "*"
  }
}

variable "nsg_flow_log_configuration" {
  type = object({
    enabled                    = bool
    network_watcher_name       = optional(string, null)
    network_watcher_rg         = optional(string, null)
    storage_account_id         = optional(string, null)
    traffic_analytics_law_name = optional(string, null)
    traffic_analytics_law_rg   = optional(string, null)
  })
  description = "(Optional) NSG flow log configuration"
  default = {
    enabled = false
  }

}
