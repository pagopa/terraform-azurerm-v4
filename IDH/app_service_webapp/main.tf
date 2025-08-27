module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "app_service"
}


variable "health_check_path" {
  default = ""
}
variable "subnet_id" {
  default = ""
}

variable "app_service_plan_name" {
  default = ""
}
variable "always_on" {
  default = ""
}
variable "docker_image" {
  default = ""
}
variable "docker_image_tag" {
  default = ""
}
variable "app_settings" {
  type = map(string)
  default = ""
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
  default = ""
}
variable "ftps_state" {
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

module "main_slot" {
  source = "../../app_service"

  vnet_integration    = module.idh_loader.idh_resource_configuration.vnet_integration
  resource_group_name = var.resource_group_name
  location            = var.location

  plan_type = "external"
  # App service plan vars
  plan_name              = var.app_service_plan_name

  sku_name               = module.idh_loader.idh_resource_configuration.sku
  zone_balancing_enabled = module.idh_loader.idh_resource_configuration.zone_balancing_enabled

  https_only = module.idh_loader.idh_resource_configuration.https_only
  client_affinity_enabled = var.client_affinity_enabled
  ftps_state = var.ftps_state
  minimum_tls_version = module.idh_loader.idh_resource_configuration.minimum_tls_version
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled

  # App service plan
  name                = var.name
  client_cert_enabled = module.idh_loader.idh_resource_configuration.client_cert_enabled
  always_on           = var.always_on


  health_check_path = var.health_check_path
  health_check_maxpingfailures = var.health_check_maxpingfailures
  app_settings = var.app_settings
  sticky_settings = var.sticky_settings
  premium_plan_auto_scale_enabled = module.idh_loader.idh_resource_configuration.premium_plan_auto_scale_enabled
  ip_restriction_default_action = module.idh_loader.idh_resource_configuration.ip_restriction_default_action
  allowed_subnets               = var.allowed_subnet_ids
  allowed_ips                   = var.allowed_ips
  allowed_service_tags = var.allowed_service_tags
  auto_heal_enabled = var.auto_heal_enabled
  auto_heal_settings = var.auto_heal_settings

  subnet_id = var.subnet_id
  docker_image        = var.docker_image
  docker_image_tag    = var.docker_image_tag
  dotnet_version = var.dotnet_version
  go_version = var.go_version
  java_server = var.java_server
  java_server_version = var.java_server_version
  java_version = var.java_version
  node_version = var.node_version
  php_version = var.php_version
  python_version = var.python_version
  ruby_version = var.ruby_version


  tags = var.tags


}

module "staging_slot" {
  count = module.idh_loader.idh_resource_configuration.slot_staging_enabled

  source = "../../app_service_slot"

  # App service plan
  # app_service_plan_id = module.printit_pdf_engine_app_service.plan_id
  app_service_id   = module.main_slot.id
  app_service_name = module.main_slot.name

  # App service
  name                = "staging"
  resource_group_name = var.resource_group_name
  location            = var.location

  https_only = module.idh_loader.idh_resource_configuration.https_only
  client_certificate_enabled = module.idh_loader.idh_resource_configuration.client_cert_enabled
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  minimum_tls_version = module.idh_loader.idh_resource_configuration.minimum_tls_version
  ip_restriction_default_action = module.idh_loader.idh_resource_configuration.ip_restriction_default_action
  vnet_integration    = module.idh_loader.idh_resource_configuration.vnet_integration

    client_affinity_enabled = var.client_affinity_enabled

  always_on         = var.always_on
  docker_image        = var.docker_image
  docker_image_tag    = var.docker_image_tag
  dotnet_version = var.dotnet_version
  go_version = var.go_version
  java_server = var.java_server
  java_server_version = var.java_server_version
  java_version = var.java_version
  node_version = var.node_version
  php_version = var.php_version
  python_version = var.python_version
  ruby_version = var.ruby_version
  health_check_path = var.health_check_path

  allowed_subnets               = var.allowed_subnet_ids
  allowed_ips                   = var.allowed_ips
  allowed_service_tags = var.allowed_service_tags
  health_check_maxpingfailures = var.health_check_maxpingfailures

  ftps_state = var.ftps_state
  # App settings
  app_settings = var.app_settings

  subnet_id = var.subnet_id

   auto_heal_enabled = var.auto_heal_enabled
  auto_heal_settings = var.auto_heal_settings



  tags = module.tag_config.tags


}
