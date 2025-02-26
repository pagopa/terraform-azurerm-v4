resource "grafana_folder" "sythetic_monitoring" {
  count    = var.enabled_sythetic_dashboard
  provider = grafana.cloud

  title = "Syntetic Monitoring Dashboard"
}

resource "grafana_dashboard" "sythetic_monitoring" {
  count    = var.enabled_sythetic_dashboard ? 1 : 0
  provider = grafana.cloud

  folder = grafana_folder.sythetic_monitoring.uid
  config_json = templatefile("./dashboards/synthetic_monitoring.tpl", {
    subscription_id           = var.subscription_id
    resource_group_name       = var.application_insight_rg_name
    application_insights_name = var.application_insight_name
  })
}
