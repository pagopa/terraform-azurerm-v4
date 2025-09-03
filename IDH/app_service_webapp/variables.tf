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
  description = "(Optional) Subnet id wether you want to integrate the app service to a subnet."
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
variable "sticky_settings" {
  type        = list(string)
  description = "(Optional) A list of app_setting names that the Linux Function App will not swap between Slots when a swap operation is triggered"
  default     = []
}

variable "client_affinity_enabled" {
  type        = bool
  description = "(Optional) Should the App Service send session affinity cookies, which route client requests in the same session to the same instance? Defaults to false."
  default     = false
}
variable "ftps_state" {
  type        = string
  description = "(Optional) Enable FTPS connection ( Default: Disabled )"
  default     = "Disabled"
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

variable "auto_heal_enabled" {
  type        = bool
  description = "(Optional) True to enable the auto heal on the app service"
  default     = false
}

variable "auto_heal_settings" {
  type = object({
    startup_time           = string
    slow_requests_count    = number
    slow_requests_interval = string
    slow_requests_time     = string
  })
  description = "(Optional) Auto heal settings"
  default     = null
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
variable "dotnet_version" {
  type    = string
  default = null
}
variable "go_version" {
  type    = string
  default = null
}
variable "java_server" {
  type    = string
  default = null
}
variable "java_server_version" {
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
variable "php_version" {
  type    = string
  default = null
}
variable "python_version" {
  type    = string
  default = null
}
variable "ruby_version" {
  type    = string
  default = null
}

variable "autoscale_settings" {
  type = object({
    max_capacity                       = number # maximum capacity for this app service
    scale_up_requests_threshold        = number # request count threshold which triggers scale up
    scale_down_requests_threshold      = number # request count threshold which triggers scale down
    scale_up_response_time_threshold   = number # response time threshold which triggers scale up
    scale_down_response_time_threshold = number # response time threshold which triggers scale down
    scale_up_cpu_threshold             = number # cpu threshold which triggers scale up
    scale_down_cpu_threshold           = number # cpu threshold which triggers scale down
  })
  default     = null
  description = "(Optional) Autoscale configuration"

  validation {
    error_message = "If scale_up_request_threshold is defined, also scale_down_request_threshold must be defined"
    condition     = (var.autoscale_settings == null) || ((var.autoscale_settings.scale_up_requests_threshold != null && var.autoscale_settings.scale_down_requests_threshold != null) || (var.autoscale_settings.scale_up_requests_threshold == null && var.autoscale_settings.scale_down_requests_threshold == null))
  }

  validation {
    error_message = "If scale_up_response_time_threshold is defined, also scale_down_response_time_threshold must be defined"
    condition     = (var.autoscale_settings == null) || ((var.autoscale_settings.scale_up_requests_threshold != null && var.autoscale_settings.scale_down_response_time_threshold != null) || (var.autoscale_settings.scale_up_requests_threshold == null && var.autoscale_settings.scale_down_response_time_threshold == null))
  }

  validation {
    error_message = "If scale_up_cpu_threshold is defined, also scale_down_cpu_threshold must be defined"
    condition     = (var.autoscale_settings == null) || ((var.autoscale_settings.scale_up_cpu_threshold != null && var.autoscale_settings.scale_down_cpu_threshold != null) || (var.autoscale_settings.scale_up_cpu_threshold == null && var.autoscale_settings.scale_down_cpu_threshold == null))
  }
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "(Optional) Subnet id where to save the private endpoint"
  default     = null
}

variable "private_endpoint_dns_zone_id" {
  type        = string
  description = "(Optional) Private DNS Zone ID to link to the private endpoint"
  default     = null
}
