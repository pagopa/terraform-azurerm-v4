locals {
  sa_prefix = replace(replace(var.prefix, "-", ""), "_", "")
}

data "azurerm_resource_group" "parent_rg" {
  name = var.resource_group_name
}

data "azurerm_application_insights" "app_insight" {
  name                = var.application_insight_name
  resource_group_name = var.application_insight_rg_name
}

#
# Storage Account
#
module "synthetic_monitoring_storage_account" {
  source = "../storage_account"

  name                = "${local.sa_prefix}synthmon"
  location            = var.location
  resource_group_name = var.resource_group_name

  account_kind                  = var.storage_account_settings.kind
  account_tier                  = var.storage_account_settings.tier
  account_replication_type      = var.storage_account_settings.replication_type
  advanced_threat_protection    = var.storage_account_settings.advanced_threat_protection
  public_network_access_enabled = var.storage_account_settings.private_endpoint_enabled ? false : true

  blob_versioning_enabled         = true
  allow_nested_items_to_be_public = false
  enable_low_availability_alert   = false
  tags                            = var.tags

  # it needs to be higher than the other retention policies
  blob_delete_retention_days           = var.storage_account_settings.backup_retention_days + 1
  blob_change_feed_enabled             = var.storage_account_settings.backup_enabled
  blob_change_feed_retention_in_days   = var.storage_account_settings.backup_enabled ? var.storage_account_settings.backup_retention_days + 1 : null
  blob_container_delete_retention_days = var.storage_account_settings.backup_retention_days
  blob_storage_policy = {
    enable_immutability_policy = false
    blob_restore_policy_days   = var.storage_account_settings.backup_retention_days
  }

  private_endpoint_enabled   = var.storage_account_settings.private_endpoint_enabled
  private_dns_zone_table_ids = [var.storage_account_settings.table_private_dns_zone_id]
  subnet_id                  = var.storage_private_endpoint_subnet_id
}

resource "azurerm_storage_table" "table_storage" {
  name                 = "monitoringconfiguration"
  storage_account_name = module.synthetic_monitoring_storage_account.name
}

#
# Apis configuration
#
locals {
  decoded_configuration = jsondecode(var.monitoring_configuration_encoded)
  monitoring_configuration = {
    for c in local.decoded_configuration :
    "${contains(keys(c), "domain") ? "${c.domain}-" : ""}${c.appName}-${c.apiName}-${c.type}" => c
    if lookup(c, "enabled", true)
  }
}

output "output_monitoring_configuration" {
  value = local.monitoring_configuration
}

resource "azurerm_storage_table_entity" "monitoring_configuration" {
  for_each         = local.monitoring_configuration
  storage_table_id = azurerm_storage_table.table_storage.id

  partition_key = "${each.value.appName}-${each.value.apiName}"
  row_key       = each.value.type
  entity = {
    "url"                 = each.value.url,
    "type"                = each.value.type,
    "checkCertificate"    = each.value.checkCertificate,
    "enabled"             = each.value.enabled,
    "alertEnabled"        = each.value.alertConfiguration.enabled,
    "method"              = each.value.method,
    "domain"              = lookup(each.value, "domain", "-"),
    "expectedCodes"       = jsonencode(each.value.expectedCodes),
    "durationLimit"       = lookup(each.value, "durationLimit", null) != null ? each.value.durationLimit : var.job_settings.default_duration_limit,
    "headers"             = lookup(each.value, "headers", null) != null ? jsonencode(each.value.headers) : null,
    "body"                = lookup(each.value, "body", null) != null ? jsonencode(each.value.body) : null
    "tags"                = lookup(each.value, "tags", null) != null ? jsonencode(each.value.tags) : null
    "bodyCompareStrategy" = lookup(each.value, "bodyCompareStrategy", null) != null ? each.value.bodyCompareStrategy : null
    "expectedBody"        = lookup(each.value, "expectedBody", null) != null ? jsonencode(each.value.expectedBody) : null
  }
}

#
# Container app JOB
#
resource "azurerm_container_app_job" "monitoring_terraform_app_job" {

  name                         = "${var.prefix}-monitoring-app-job"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  container_app_environment_id = var.job_settings.container_app_environment_id

  identity {
    type = "SystemAssigned"
  }

  schedule_trigger_config {
    cron_expression          = var.job_settings.cron_scheduling
    parallelism              = 1
    replica_completion_count = 1
  }

  workload_profile_name = "Consumption"

  template {
    container {
      cpu    = var.job_settings.cpu_requirement
      memory = var.job_settings.memory_requirement
      name   = "synthetic-monitoring"
      image  = "${var.docker_settings.registry_url}/${var.docker_settings.image_name}:${var.docker_settings.image_tag}"

      env {
        name  = "APP_INSIGHT_CONNECTION_STRING"
        value = data.azurerm_application_insights.app_insight.connection_string
      }
      env {
        name  = "STORAGE_ACCOUNT_NAME"
        value = module.synthetic_monitoring_storage_account.name
      }
      env {
        name  = "STORAGE_ACCOUNT_KEY"
        value = module.synthetic_monitoring_storage_account.primary_access_key
      }
      env {
        name  = "STORAGE_ACCOUNT_TABLE_NAME"
        value = azurerm_storage_table.table_storage.name
      }
      env {
        name  = "AVAILABILITY_PREFIX"
        value = var.job_settings.availability_prefix
      }
      env {
        name  = "HTTP_CLIENT_TIMEOUT"
        value = tostring(var.job_settings.http_client_timeout)
      }
      env {
        name  = "LOCATION"
        value = var.location
      }
      env {
        name  = "CERT_VALIDITY_RANGE_DAYS"
        value = tostring(var.job_settings.cert_validity_range_days)
      }
    }
  }

  replica_retry_limit        = 1
  replica_timeout_in_seconds = var.job_settings.execution_timeout_seconds

  tags = var.tags
}

#
# Alerts configuration
#
locals {
  default_alert_configuration = {
    enabled       = true,
    severity      = 0,
    frequency     = "PT1M"
    auto_mitigate = var.alert_set_auto_mitigate
    threshold     = 100
    operator      = "LessThan"
    aggregation   = "Average"
  }

  default_custom_action_groups = []
}

resource "azurerm_monitor_metric_alert" "alert" {
  for_each = local.monitoring_configuration

  name                = "availability-${contains(keys(each.value), "domain") ? "${each.value.domain}-" : ""}${each.value.appName}-${each.value.apiName}-${each.value.type}"
  resource_group_name = var.resource_group_name

  scopes        = [data.azurerm_application_insights.app_insight.id]
  description   = "Availability of ${contains(keys(each.value), "domain") ? "${each.value.domain}-" : ""}${each.value.appName} ${each.value.apiName} from ${each.value.type} degraded"
  severity      = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "severity", local.default_alert_configuration.severity)
  frequency     = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "frequency", local.default_alert_configuration.frequency)
  auto_mitigate = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "auto_mitigate", local.default_alert_configuration.auto_mitigate)
  enabled       = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "enabled", local.default_alert_configuration.enabled)

  criteria {
    aggregation      = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "aggregation", local.default_alert_configuration.aggregation)
    metric_name      = "availabilityResults/availabilityPercentage"
    metric_namespace = "microsoft.insights/components"
    operator         = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "operator", local.default_alert_configuration.operator)
    threshold        = lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "threshold", local.default_alert_configuration.threshold)
    dimension {
      name     = "availabilityResult/name"
      operator = "Include"
      values = [
        "${var.job_settings.availability_prefix}-${contains(keys(each.value), "domain") ? "${each.value.domain}-" : ""}${each.value.appName}-${each.value.apiName}"
      ]
    }
    dimension {
      name     = "availabilityResult/location"
      operator = "Include"
      values   = [each.value.type]
    }
  }

  dynamic "action" {
    for_each = concat(var.application_insights_action_group_ids, lookup(lookup(each.value, "alertConfiguration", local.default_alert_configuration), "customActionGroupIds", local.default_custom_action_groups))

    content {
      action_group_id = action.value
    }
  }

  depends_on = [azurerm_container_app_job.monitoring_terraform_app_job]
}

#
# Self Alert
#
resource "azurerm_monitor_metric_alert" "self_alert" {
  name                = "availability-synthetic-monitoring-function"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_application_insights.app_insight.id]
  description         = "Monitors the availability of the synthetic monitoring function"
  severity            = var.self_alert_configuration.severity
  frequency           = var.self_alert_configuration.frequency
  auto_mitigate       = true
  enabled             = var.self_alert_configuration.enabled

  criteria {
    aggregation      = var.self_alert_configuration.aggregation
    metric_name      = "availabilityResults/availabilityPercentage"
    metric_namespace = "microsoft.insights/components"
    operator         = var.self_alert_configuration.operator
    threshold        = var.self_alert_configuration.threshold
    dimension {
      name     = "availabilityResult/name"
      operator = "Include"
      values   = ["${var.job_settings.availability_prefix}-monitoring-function"]
    }
    dimension {
      name     = "availabilityResult/location"
      operator = "Include"
      values   = [var.location]
    }
  }

  dynamic "action" {
    for_each = var.application_insights_action_group_ids

    content {
      action_group_id = action.value
    }
  }
}
