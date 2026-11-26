resource "helm_release" "helm_tls_checker_this" {
  for_each = local.certificates_with_chart

  namespace    = each.value.namespace
  name         = local.tls_checker_helm_chart_names[each.key]
  chart        = "microservice-chart"
  repository   = "https://pagopa.github.io/aks-microservice-chart-blueprint"
  version      = each.value.helm_chart_version
  timeout      = 180
  force_update = true

  values = [
    templatefile("${path.module}/templates/tls-cert-workload-identity.yaml.tpl",
      {
        namespace                                                 = each.value.namespace
        image_name                                                = each.value.helm_chart_image_name
        image_tag                                                 = each.value.helm_chart_image_tag
        website_site_name                                         = each.value.https_endpoint
        time_trigger                                              = each.value.time_trigger
        function_name                                             = each.value.https_endpoint
        region                                                    = each.value.location_string
        expiration_delta_in_days                                  = each.value.expiration_delta_in_days
        host                                                      = each.value.https_endpoint
        keyvault_name                                             = each.value.keyvault_name
        keyvault_tenant_id                                        = each.value.keyvault_tenant_id
        kv_secret_name_for_application_insights_connection_string = each.value.kv_secret_name_for_application_insights_connection_string
        SERVICE_ACCOUNT_NAME                                      = each.value.service_account_name
        WORKLOAD_IDENTITY_CLIENT_ID                               = each.value.workload_identity_client_id
    })
  ]
}

#
# 📢 Alert
#
resource "azurerm_monitor_metric_alert" "alert_this" {
  for_each = local.certificates

  name                = local.tls_checker_alert_names[each.key]
  resource_group_name = each.value.application_insights_resource_group
  scopes              = [each.value.application_insights_id]
  description         = "Whenever the average availabilityresults/availabilitypercentage is less than 50%"
  severity            = 0
  frequency           = "PT5M"
  auto_mitigate       = false
  enabled             = each.value.alert_enabled

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 50

    dimension {
      name     = "availabilityResult/name"
      operator = "Include"
      values   = [each.value.https_endpoint]
    }
  }

  dynamic "action" {
    for_each = each.value.application_insights_action_group_ids

    content {
      action_group_id = action.value
    }
  }

  depends_on = [
    helm_release.helm_tls_checker_this
  ]
}


resource "helm_release" "helm_reloader_this" {
  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = "v2.2.18"
  namespace  = var.namespace

  set {
    name  = "reloader.watchGlobally"
    value = "false"
  }
  set {
    name  = "reloader.deployment.resources.requests.cpu"
    value = "10m"
  }
  set {
    name  = "reloader.deployment.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "reloader.deployment.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "reloader.deployment.resources.limits.memory"
    value = "256Mi"
  }
}


resource "helm_release" "helm_cert_mounter_this" {
  for_each = local.certificates

  name         = replace(substr(each.value.release_name, 0, 53), ".", "-")
  repository   = "https://pagopa.github.io/aks-helm-cert-mounter-blueprint"
  chart        = "cert-mounter-blueprint"
  version      = each.value.cert_mounter_chart_version
  namespace    = each.value.namespace
  timeout      = 120
  force_update = true

  values = [
    templatefile("${path.module}/templates/cert-mounter-workload-identity.yaml.tpl", {
      NAMESPACE                   = each.value.namespace,
      CERTIFICATE_NAME            = each.value.certificate_name,
      KEY_VAULT_NAME              = each.value.keyvault_name,
      TENANT_ID                   = each.value.keyvault_tenant_id,
      SERVICE_ACCOUNT_NAME        = each.value.service_account_name,
      WORKLOAD_IDENTITY_CLIENT_ID = each.value.workload_identity_client_id,
      POD_RAM                     = each.value.pod_ram
      POD_CPU                     = each.value.pod_cpu
      TOLERATIONS                 = each.value.tolerations
      AFFINITY                    = each.value.affinity
    })
  ]
}
