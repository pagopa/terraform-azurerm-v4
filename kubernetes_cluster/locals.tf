locals {
  aks_fqdn_levels               = length(split(".", azurerm_kubernetes_cluster.this.private_fqdn))
  managed_private_dns_zone_name = join(".", slice(split(".", azurerm_kubernetes_cluster.this.private_fqdn), 1, local.aks_fqdn_levels))
  metric_alerts                 = merge(var.default_metric_alerts, var.custom_metric_alerts)
  log_alerts                    = merge(var.custom_logs_alerts, local.default_logs_alerts)

  default_logs_alerts = {
    ### NODE NOT READY ALERT
    node_not_ready = {
      display_name            = "${azurerm_kubernetes_cluster.this.name}-NODE-NOT-READY"
      description             = "Detect nodes that is not ready on AKS cluster"
      query                   = <<-KQL
        KubeNodeInventory
        | where ClusterId == "${azurerm_kubernetes_cluster.this.id}"
        | where TimeGenerated > ago(15m)
        | where Status == "NotReady"
        | summarize count() by Computer, Status
      KQL
      severity                = 1
      window_duration         = "PT30M"
      evaluation_frequency    = "PT10M"
      operator                = "GreaterThan"
      threshold               = 1
      time_aggregation_method = "Average"
      resource_id_column      = "Status"
      metric_measure_column   = "count_"
      dimension = [
        {
          name     = "Computer"
          operator = "Include"
          values   = ["*"]
        }
      ]
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
      auto_mitigation_enabled                  = true
      workspace_alerts_storage_enabled         = false
      skip_query_validation                    = true
    }
    ### NODE DISK ALERT
    node_disk_usage = {
      display_name            = "${azurerm_kubernetes_cluster.this.name}-NODE-DISK-USAGE"
      description             = "Detect nodes disk is going to run out of space"
      query                   = <<-KQL
        InsightsMetrics
        | where _ResourceId == "${lower(azurerm_kubernetes_cluster.this.id)}"
        | where TimeGenerated > ago(15m)
        | where Namespace == "container.azm.ms/disk"
        | where Name == "used_percent"
        | project TimeGenerated, Computer, Val, Origin
        | summarize AvgDiskUsage = avg(Val) by Computer
      KQL
      severity                = 2
      window_duration         = "PT30M"
      evaluation_frequency    = "PT10M"
      operator                = "GreaterThan"
      threshold               = 90
      time_aggregation_method = "Average"
      resource_id_column      = "AvgDiskUsage"
      metric_measure_column   = "AvgDiskUsage"
      dimension = [
        {
          name     = "Computer"
          operator = "Include"
          values   = ["*"]
        }
      ]
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
      auto_mitigation_enabled                  = true
      workspace_alerts_storage_enabled         = false
      skip_query_validation                    = true
    }
  }
}
