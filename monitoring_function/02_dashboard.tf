resource "grafana_folder" "sythetic_monitoring" {
  count = var.enabled_sythetic_dashboard ? 1 : 0

  title = "Syntetic Monitoring Dashboard"
}

resource "grafana_dashboard" "sythetic_monitoring" {
  count = var.enabled_sythetic_dashboard ? 1 : 0

  folder = grafana_folder.sythetic_monitoring[0].uid
  config_json = templatefile("${path.module}/dashboards/synthetic_monitoring.tpl", {
    subscription_id           = var.subscription_id
    resource_group_name       = var.application_insight_rg_name
    application_insights_name = var.application_insight_name
  })
  depends_on = [grafana_folder.sythetic_monitoring]
}
