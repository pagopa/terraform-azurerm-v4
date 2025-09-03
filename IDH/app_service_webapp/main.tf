module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "app_service_webapp"
}


module "main_slot" {
  source = "../../app_service"

  vnet_integration    = module.idh_loader.idh_resource_configuration.vnet_integration
  resource_group_name = var.resource_group_name
  location            = var.location

  plan_type = module.idh_loader.idh_resource_configuration.plan_type
  # App service plan vars
  plan_name = var.app_service_plan_name

  sku_name               = module.idh_loader.idh_resource_configuration.sku
  zone_balancing_enabled = module.idh_loader.idh_resource_configuration.zone_balancing_enabled

  https_only                    = module.idh_loader.idh_resource_configuration.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  ftps_state                    = var.ftps_state
  minimum_tls_version           = module.idh_loader.idh_resource_configuration.minimum_tls_version
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled

  # App service plan
  name                = var.name
  client_cert_enabled = module.idh_loader.idh_resource_configuration.client_cert_enabled
  always_on           = var.always_on


  health_check_path               = var.health_check_path
  health_check_maxpingfailures    = var.health_check_maxpingfailures
  app_settings                    = var.app_settings
  sticky_settings                 = var.sticky_settings
  premium_plan_auto_scale_enabled = module.idh_loader.idh_resource_configuration.premium_plan_auto_scale_enabled
  ip_restriction_default_action   = module.idh_loader.idh_resource_configuration.ip_restriction_default_action
  allowed_subnets                 = var.allowed_subnet_ids
  allowed_ips                     = var.allowed_ips
  allowed_service_tags            = var.allowed_service_tags
  auto_heal_enabled               = var.auto_heal_enabled
  auto_heal_settings              = var.auto_heal_settings

  subnet_id           = var.subnet_id
  docker_image        = var.docker_image
  docker_image_tag    = var.docker_image_tag
  docker_registry_url = var.docker_registry_url
  dotnet_version      = var.dotnet_version
  go_version          = var.go_version
  java_server         = var.java_server
  java_server_version = var.java_server_version
  java_version        = var.java_version
  node_version        = var.node_version
  php_version         = var.php_version
  python_version      = var.python_version
  ruby_version        = var.ruby_version


  tags = var.tags


}

module "staging_slot" {
  count = module.idh_loader.idh_resource_configuration.slot_staging_enabled ? 1 : 0

  source = "../../app_service_slot"

  # App service plan
  # app_service_plan_id = module.printit_pdf_engine_app_service.plan_id
  app_service_id   = module.main_slot.id
  app_service_name = module.main_slot.name

  # App service
  name                = "staging"
  resource_group_name = var.resource_group_name
  location            = var.location

  https_only                    = module.idh_loader.idh_resource_configuration.https_only
  client_certificate_enabled    = module.idh_loader.idh_resource_configuration.client_cert_enabled
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  minimum_tls_version           = module.idh_loader.idh_resource_configuration.minimum_tls_version
  ip_restriction_default_action = module.idh_loader.idh_resource_configuration.ip_restriction_default_action
  vnet_integration              = module.idh_loader.idh_resource_configuration.vnet_integration

  client_affinity_enabled = var.client_affinity_enabled

  always_on           = var.always_on
  docker_image        = var.docker_image
  docker_image_tag    = var.docker_image_tag
  dotnet_version      = var.dotnet_version
  go_version          = var.go_version
  java_server         = var.java_server
  java_server_version = var.java_server_version
  java_version        = var.java_version
  node_version        = var.node_version
  php_version         = var.php_version
  python_version      = var.python_version
  ruby_version        = var.ruby_version
  health_check_path   = var.health_check_path

  allowed_subnets              = var.allowed_subnet_ids
  allowed_ips                  = var.allowed_ips
  allowed_service_tags         = var.allowed_service_tags
  health_check_maxpingfailures = var.health_check_maxpingfailures

  ftps_state = var.ftps_state
  # App settings
  app_settings = var.app_settings

  subnet_id = var.subnet_id

  auto_heal_enabled  = var.auto_heal_enabled
  auto_heal_settings = var.auto_heal_settings


  tags = var.tags
}



resource "azurerm_monitor_autoscale_setting" "autoscale_settings" {
  count = module.idh_loader.idh_resource_configuration.autoscale_enabled ? 1 : 0


  name                = "${var.name}-autoscale-settings"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = module.main_slot.plan_id
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
          value     = "2"
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
          value     = "2"
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
          metric_resource_id       = module.main_slot.plan_id
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
          value     = "2"
          cooldown  = "PT5M"
        }
      }
    }

    dynamic "rule" {
      for_each = var.autoscale_settings.scale_down_cpu_threshold != null ? [1] : []
      content {
        metric_trigger {
          metric_name              = "CpuPercentage"
          metric_resource_id       = module.main_slot.plan_id
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
          metric_resource_id       = module.main_slot.plan_id
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
  subnet_id           = var.private_endpoint_subnet_id

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
  subnet_id           = var.private_endpoint_subnet_id

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
