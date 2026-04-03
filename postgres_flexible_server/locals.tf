locals {
  metric_alerts = var.custom_metric_alerts != null ? var.custom_metric_alerts : var.default_metric_alerts
}
