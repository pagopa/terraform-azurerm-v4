module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "app_service_function"
}

# IDH/subnet ingress
module "private_endpoint_snet" {
  count                = var.embedded_subnet.enabled && module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? 1 : 0
  source               = "../subnet"
  name                 = "${var.name}-ingress-pe-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  env               = var.env
  idh_resource_tier = "slash28_privatelink_true"
  product_name      = var.product_name

  tags = var.tags
}

# IDH/subnet egress
module "egress_snet" {
  count                = var.embedded_subnet.enabled ? 1 : 0
  source               = "../subnet"
  name                 = "${var.name}-egress-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  env               = var.env
  idh_resource_tier = "app_service"
  product_name      = var.product_name

  tags = var.tags
}


resource "azurerm_app_service_plan" "function_service_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name

  kind     = module.idh_loader.idh_resource_configuration.plan.kind
  reserved = module.idh_loader.idh_resource_configuration.plan.kind == "Linux" ? true : false

  zone_redundant = module.idh_loader.idh_resource_configuration.plan.zone_balancing_enabled

  maximum_elastic_worker_count = module.idh_loader.idh_resource_configuration.plan.kind == "elastic" ? module.idh_loader.idh_resource_configuration.plan.maximum_elastic_worker_count : null

  sku {
    tier     = module.idh_loader.idh_resource_configuration.plan.sku_tier
    size     = module.idh_loader.idh_resource_configuration.plan.sku_size
    capacity = 1
  }

  tags = var.tags
}



## Function reporting_analysis
module "main_slot" {
  source = "../../function_app"

  resource_group_name  = var.resource_group_name
  name                 = var.name
  storage_account_name = replace("${var.name}-st", "-", "")
  location             = var.location
  health_check_path    = var.health_check_path
  subnet_id            = var.embedded_subnet.enabled ? module.egress_snet[0].subnet_id : var.subnet_id

  docker = {
    registry_url      = var.docker_registry_url
    image_name        = var.docker_image
    image_tag         = var.docker_image_tag
    registry_username = null
    registry_password = null
  }

  internal_storage = var.internal_storage

  always_on                                = var.always_on
  application_insights_instrumentation_key = var.application_insights_instrumentation_key
  app_service_plan_id                      = azurerm_app_service_plan.function_service_plan.id
  app_service_plan_type                    = module.idh_loader.idh_resource_configuration.plan_type
  app_settings                             = var.app_settings

  allowed_subnets      = var.allowed_subnet_ids
  allowed_ips          = var.allowed_ips
  allowed_service_tags = var.allowed_service_tags
  action               = var.action
  app_service_logs     = var.app_service_logs

  health_check_maxpingfailures   = var.health_check_maxpingfailures
  healthcheck_threshold          = var.healthcheck_threshold
  cors                           = var.cors
  domain                         = var.domain
  dotnet_version                 = var.dotnet_version
  java_version                   = var.java_version
  node_version                   = var.node_version
  powershell_core_version        = var.powershell_core_version
  pre_warmed_instance_count      = var.pre_warmed_instance_count
  python_version                 = var.python_version
  sticky_app_setting_names       = var.sticky_app_setting_names
  sticky_connection_string_names = var.sticky_connection_string_names
  storage_account_durable_name   = var.storage_account_durable_name
  use_custom_runtime             = var.use_custom_runtime
  use_dotnet_isolated_runtime    = var.use_dotnet_isolated_runtime

  export_keys = true

  runtime_version = module.idh_loader.idh_resource_configuration.runtime_version
  storage_account_info = {
    account_kind                      = module.idh_loader.idh_resource_configuration.storage_account.account_kind
    account_tier                      = module.idh_loader.idh_resource_configuration.storage_account.account_tier
    account_replication_type          = module.idh_loader.idh_resource_configuration.storage_account.replication_type
    access_tier                       = module.idh_loader.idh_resource_configuration.storage_account.access_tier
    advanced_threat_protection_enable = module.idh_loader.idh_resource_configuration.storage_account.advanced_threat_protection_enabled
    public_network_access_enabled     = module.idh_loader.idh_resource_configuration.storage_account.public_network_access_enabled
    use_legacy_defender_version       = module.idh_loader.idh_resource_configuration.storage_account.use_legacy_defender_version
  }
  client_certificate_enabled                = module.idh_loader.idh_resource_configuration.client_cert_enabled
  client_certificate_mode                   = module.idh_loader.idh_resource_configuration.client_cert_mode
  enable_function_app_public_network_access = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  enable_healthcheck                        = module.idh_loader.idh_resource_configuration.enable_healthcheck
  https_only                                = module.idh_loader.idh_resource_configuration.https_only
  internal_storage_account_info = {
    account_kind                      = module.idh_loader.idh_resource_configuration.internal_storage_account.account_kind
    account_tier                      = module.idh_loader.idh_resource_configuration.internal_storage_account.account_tier
    account_replication_type          = module.idh_loader.idh_resource_configuration.internal_storage_account.replication_type
    access_tier                       = module.idh_loader.idh_resource_configuration.internal_storage_account.access_tier
    advanced_threat_protection_enable = module.idh_loader.idh_resource_configuration.internal_storage_account.advanced_threat_protection_enabled
    use_legacy_defender_version       = module.idh_loader.idh_resource_configuration.internal_storage_account.use_legacy_defender_version
    public_network_access_enabled     = module.idh_loader.idh_resource_configuration.internal_storage_account.public_network_access_enabled
  }
  ip_restriction_default_action = module.idh_loader.idh_resource_configuration.ip_restriction_default_action
  minimum_tls_version           = module.idh_loader.idh_resource_configuration.minimum_tls_version
  system_identity_enabled       = module.idh_loader.idh_resource_configuration.system_identity_enabled
  use_32_bit_worker_process     = module.idh_loader.idh_resource_configuration.use_32_bit_worker_process
  vnet_integration              = module.idh_loader.idh_resource_configuration.vnet_integration


  tags = var.tags

}


module "reporting_analysis_function_slot_staging" {
  count = module.idh_loader.idh_resource_configuration.slot_staging_enabled ? 1 : 0

  source = "../../function_app_slot"

  function_app_id                          = module.main_slot.id
  storage_account_name                     = module.main_slot.storage_account_name
  storage_account_access_key               = module.main_slot.storage_account.primary_access_key
  name                                     = "staging"
  resource_group_name                      = var.resource_group_name
  location                                 = var.location
  application_insights_instrumentation_key = var.application_insights_instrumentation_key

  always_on         = var.always_on
  health_check_path = var.health_check_path
  runtime_version   = module.idh_loader.idh_resource_configuration.runtime_version

  # App settings
  app_settings = var.app_settings

  docker = {
    registry_url      = var.docker_registry_url
    image_name        = var.docker_image
    image_tag         = var.docker_image_tag
    registry_username = null
    registry_password = null
  }

  allowed_subnets      = var.allowed_subnet_ids
  allowed_ips          = var.allowed_ips
  allowed_service_tags = var.allowed_service_tags

  subnet_id = var.embedded_subnet.enabled ? module.egress_snet[0].subnet_id : var.subnet_id

  tags = var.tags

  auto_swap_slot_name                       = try(module.idh_loader.idh_resource_configuration.auto_swap_slot_name, null)
  client_certificate_enabled                = module.idh_loader.idh_resource_configuration.client_cert_enabled
  cors                                      = var.cors
  dotnet_version                            = var.dotnet_version
  enable_function_app_public_network_access = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  export_keys                               = true
  health_check_maxpingfailures              = var.health_check_maxpingfailures
  https_only                                = module.idh_loader.idh_resource_configuration.https_only

  internal_storage_connection_string = var.internal_storage.enable ? module.main_slot.storage_account_internal_function.primary_connection_string : null

  java_version                = var.java_version
  node_version                = var.node_version
  powershell_core_version     = var.powershell_core_version
  pre_warmed_instance_count   = var.pre_warmed_instance_count
  python_version              = var.python_version
  use_custom_runtime          = var.use_custom_runtime
  use_dotnet_isolated_runtime = var.use_dotnet_isolated_runtime

  ip_restriction_default_action = module.idh_loader.idh_resource_configuration.ip_restriction_default_action
  minimum_tls_version           = module.idh_loader.idh_resource_configuration.minimum_tls_version
  system_identity_enabled       = module.idh_loader.idh_resource_configuration.system_identity_enabled
  use_32_bit_worker_process     = module.idh_loader.idh_resource_configuration.use_32_bit_worker_process
  vnet_integration              = module.idh_loader.idh_resource_configuration.vnet_integration


}





resource "azurerm_monitor_autoscale_setting" "autoscale_settings" {
  count = module.idh_loader.idh_resource_configuration.autoscale_enabled ? 1 : 0


  name                = "${var.name}-autoscale-settings"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_app_service_plan.function_service_plan.id
  enabled             = module.idh_loader.idh_resource_configuration.autoscale_enabled

  profile {
    name = "default"

    capacity {
      default = module.idh_loader.idh_resource_configuration.autoscale_default_capacity
      minimum = module.idh_loader.idh_resource_configuration.autoscale_min_capacity
      maximum = var.autoscale_settings.max_capacity
    }

    dynamic "rule" {
      for_each = var.autoscale_settings.scale_up_requests_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "Requests"
          metric_resource_id       = module.main_slot.id
          metric_namespace         = "microsoft.web/sites"
          time_grain               = "PT1M"
          statistic                = "Average"
          time_window              = "PT5M"
          time_aggregation         = "Average"
          operator                 = "GreaterThan"
          threshold                = var.autoscale_settings.scale_up_requests_threshold
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Increase"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT5M"
        }
      }
    }

    dynamic "rule" {
      for_each = var.autoscale_settings.scale_down_requests_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "Requests"
          metric_resource_id       = module.main_slot.id
          metric_namespace         = "microsoft.web/sites"
          time_grain               = "PT1M"
          statistic                = "Average"
          time_window              = "PT5M"
          time_aggregation         = "Average"
          operator                 = "LessThan"
          threshold                = var.autoscale_settings.scale_down_requests_threshold
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Decrease"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT20M"
        }
      }
    }

    # HttpResponseTime

    # Supported metrics for Microsoft.Web/sites
    # 👀 https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-web-sites-metrics
    dynamic "rule" {
      for_each = var.autoscale_settings.scale_up_response_time_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name        = "HttpResponseTime"
          metric_resource_id = module.main_slot.id
          metric_namespace   = "microsoft.web/sites"
          time_grain         = "PT1M"
          statistic          = "Average"
          time_window        = "PT5M"
          time_aggregation   = "Average"
          operator           = "GreaterThan"
          threshold          = var.autoscale_settings.scale_up_response_time_threshold
          #sec
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Increase"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT5M"
        }
      }
    }
    dynamic "rule" {
      for_each = var.autoscale_settings.scale_down_response_time_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "HttpResponseTime"
          metric_resource_id       = module.main_slot.id
          metric_namespace         = "microsoft.web/sites"
          time_grain               = "PT1M"
          statistic                = "Average"
          time_window              = "PT5M"
          time_aggregation         = "Average"
          operator                 = "LessThan"
          threshold                = var.autoscale_settings.scale_down_response_time_threshold #sec
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Decrease"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT20M"
        }
      }
    }



    # CpuPercentage

    # Supported metrics for Microsoft.Web/sites
    # 👀 https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-web-sites-metrics
    dynamic "rule" {
      for_each = var.autoscale_settings.scale_up_cpu_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "CpuPercentage"
          metric_resource_id       = module.main_slot.id
          metric_namespace         = "microsoft.web/serverfarms"
          time_grain               = "PT1M"
          statistic                = "Average"
          time_window              = "PT5M"
          time_aggregation         = "Average"
          operator                 = "GreaterThan"
          threshold                = var.autoscale_settings.scale_up_cpu_threshold
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Increase"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT5M"
        }
      }
    }

    dynamic "rule" {
      for_each = var.autoscale_settings.scale_down_cpu_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "CpuPercentage"
          metric_resource_id       = module.main_slot.id
          metric_namespace         = "microsoft.web/serverfarms"
          time_grain               = "PT1M"
          statistic                = "Average"
          time_window              = "PT5M"
          time_aggregation         = "Average"
          operator                 = "LessThan"
          threshold                = var.autoscale_settings.scale_down_cpu_threshold
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Decrease"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT20M"
        }
      }
    }

    dynamic "rule" {
      for_each = var.autoscale_settings.scale_down_cpu_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "CpuPercentage"
          metric_resource_id       = module.main_slot.id
          metric_namespace         = "microsoft.web/serverfarms"
          time_grain               = "PT1M"
          statistic                = "Average"
          time_window              = "PT5M"
          time_aggregation         = "Average"
          operator                 = "LessThan"
          threshold                = var.autoscale_settings.scale_down_cpu_threshold
          divide_by_instance_count = false
        }

        scale_action {
          direction = "Decrease"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT20M"
        }
      }
    }
  }
}


resource "azurerm_private_endpoint" "main_slot_private_endpoint" {
  count = module.idh_loader.idh_resource_configuration.private_endpoint_enabled ? 1 : 0

  name                = "${var.name}-main-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.embedded_subnet.enabled ? module.private_endpoint_snet[0].subnet_id : var.private_endpoint_subnet_id

  private_dns_zone_group {
    name                 = "${var.name}-main-dns-zone-group"
    private_dns_zone_ids = [var.private_endpoint_dns_zone_id]
  }

  private_service_connection {
    name                           = "${var.name}-main-service-connection"
    private_connection_resource_id = module.main_slot.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "staging_slot_private_endpoint" {
  count = module.idh_loader.idh_resource_configuration.private_endpoint_enabled && module.idh_loader.idh_resource_configuration.slot_staging_enabled ? 1 : 0

  name                = "${var.name}-staging-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.embedded_subnet.enabled ? module.private_endpoint_snet[0].subnet_id : var.private_endpoint_subnet_id

  private_dns_zone_group {
    name                 = "${var.name}-staging-dns-zone-group"
    private_dns_zone_ids = [var.private_endpoint_dns_zone_id]
  }

  private_service_connection {
    name                           = "${var.name}-staging-service-connection"
    private_connection_resource_id = module.main_slot.id #issue https://github.com/hashicorp/terraform-provider-azurerm/issues/11147
    is_manual_connection           = false
    subresource_names              = ["sites-staging"]
  }

  tags = var.tags
}
