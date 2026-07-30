#
# Monitor Metrics
#
resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.metric_alerts

  name                = "${azurerm_kubernetes_cluster.this.name}-${upper(each.key)}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  description         = each.value.description
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  enabled             = var.alerts_enabled
  severity            = lookup(each.value, "severity", 3)

  dynamic "action" {
    for_each = var.action
    content {
      # action_group_id - (required) is a type of string
      action_group_id = action.value["action_group_id"]
      # webhook_properties - (optional) is a type of map of string
      webhook_properties = action.value["webhook_properties"]
    }
  }

  criteria {
    aggregation            = each.value.aggregation
    metric_namespace       = each.value.metric_namespace
    metric_name            = each.value.metric_name
    operator               = each.value.operator
    threshold              = each.value.threshold
    skip_metric_validation = each.value.skip_metric_validation

    dynamic "dimension" {
      for_each = each.value.dimension
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each = local.log_alerts

  name         = "${azurerm_kubernetes_cluster.this.name}-${upper(each.key)}"
  description  = each.value.description
  display_name = each.value.display_name
  enabled      = var.alerts_enabled

  resource_group_name  = var.resource_group_name
  scopes               = [azurerm_kubernetes_cluster.this.id]
  location             = var.location
  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration

  # Assuming each.value includes this attribute
  severity = each.value.severity

  criteria {
    query                   = each.value.query
    operator                = each.value.operator
    threshold               = each.value.threshold
    time_aggregation_method = lookup(each.value, "time_aggregation_method", "Average")

    resource_id_column    = each.value.resource_id_column
    metric_measure_column = lookup(each.value, "metric_measure_column", null)

    dynamic "dimension" {
      for_each = each.value.dimension
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = lookup(each.value, "minimum_failing_periods_to_trigger_alert", 1)
      number_of_evaluation_periods             = lookup(each.value, "number_of_evaluation_periods", 1)
    }
  }

  auto_mitigation_enabled          = lookup(each.value, "auto_mitigation_enabled", true)
  workspace_alerts_storage_enabled = lookup(each.value, "workspace_alerts_storage_enabled", false)
  skip_query_validation            = lookup(each.value, "skip_query_validation", true)

  action {
    // Concatenazione di tutti gli ID dei gruppi d'azione in un singolo set di stringhe
    action_groups     = [for g in var.action : g.action_group_id]
    custom_properties = {}
  }

  tags = var.tags

  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.sec_log_analytics_workspace_id != null ? 1 : 0
  name                       = "LogSecurity"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.sec_log_analytics_workspace_id
  storage_account_id         = var.sec_storage_id

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "cloud-controller-manager"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "csi-azuredisk-controller"
  }

  enabled_log {
    category = "csi-azurefile-controller"
  }

  enabled_log {
    category = "csi-snapshot-controller"
  }

  enabled_log {
    category = "guard"
  }

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }

  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}


#-------------------------------------------------------------------------------
# AMA - Azure Monitor Agent logs filter
#-------------------------------------------------------------------------------

resource "kubernetes_config_map_v1" "ama_logs_settings" {
  count = length(var.ama_log_collection_settings.include_namespaces) > 0 ? 1 : 0

  metadata {
    name      = "container-azm-ms-agentconfig"
    namespace = "kube-system"
  }

  data = {
    "schema-version" = "v1"
    "config-version" = "ver1"

    "log-data-collection-settings" = templatefile(
      "${path.module}/templates/log-data-collection-settings.tftpl",
      {
        include_namespaces          = var.ama_log_collection_settings.include_namespaces
        containerlog_schema_version = var.ama_log_collection_settings.containerlog_schema_version
        enable_multiline_logs       = var.ama_log_collection_settings.enable_multiline_logs
        filter_using_annotations    = var.ama_log_collection_settings.filter_using_annotations
        collect_env_vars            = var.ama_log_collection_settings.collect_env_vars
        enrich_container_logs       = var.ama_log_collection_settings.enrich_container_logs
        collect_all_kube_events     = var.ama_log_collection_settings.collect_all_kube_events
      }
    )
  }
}
