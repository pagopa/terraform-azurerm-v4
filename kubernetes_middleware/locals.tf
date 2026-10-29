locals {
  alert_name                = var.alert_name != null ? lower(replace(var.alert_name, "/\\W/", "-")) : lower(replace(var.https_endpoint, "/\\W/", "-"))
  alert_name_sha256_limited = substr(sha256(var.alert_name), 0, 5)
  # all this work is mandatory to avoid helm name limit of 53 chars
  helm_chart_name = "${lower(substr(replace("chckr-${var.alert_name}", "/\\W/", "-"), 0, 47))}${local.alert_name_sha256_limited}"
  chart_version   = var.workload_identity_enabled ? var.helm_chart_version : "5.9.1"
}
