locals {
  certificate_default_key = "default"
  # The empty-object fallback must list every attribute explicitly: conditional-expression
  # type unification does not fill in optional object attributes the way direct variable
  # assignment does, so an actual `{}` here would make `value.<attr>` below fail.
  certificates_input = length(var.certificates) > 0 ? var.certificates : {
    (local.certificate_default_key) = {
      https_endpoint                                            = null
      certificate_name                                          = null
      location_string                                           = null
      alert_name                                                = null
      namespace                                                 = null
      time_trigger                                              = null
      expiration_delta_in_days                                  = null
      keyvault_name                                             = null
      keyvault_tenant_id                                        = null
      kv_secret_name_for_application_insights_connection_string = null
      service_account_name                                      = null
      workload_identity_client_id                               = null
      helm_chart_present                                        = null
      helm_chart_version                                        = null
      helm_chart_image_name                                     = null
      helm_chart_image_tag                                      = null
      alert_enabled                                             = null
      application_insights_resource_group                       = null
      application_insights_id                                   = null
      application_insights_action_group_ids                     = null
      pod_ram                                                   = null
      pod_cpu                                                   = null
      tolerations                                               = null
      affinity                                                  = null
      cert_mounter_chart_version                                = null
      release_name                                              = null
    }
  }

  # Resolves each certificates entry against the top-level variables, so unset
  # attributes keep the previous single-certificate defaults. Ternaries, not
  # coalesce(): coalesce() also skips empty strings, which are valid
  # overrides/defaults here (e.g. tolerations/affinity default to "").
  certificates = {
    for key, value in local.certificates_input : key => {
      https_endpoint                                            = value.https_endpoint != null ? value.https_endpoint : var.https_endpoint
      certificate_name                                          = value.certificate_name != null ? value.certificate_name : replace(coalesce(value.https_endpoint, var.https_endpoint), ".", "-")
      location_string                                           = value.location_string != null ? value.location_string : var.location_string
      alert_name                                                = value.alert_name != null ? value.alert_name : var.alert_name
      namespace                                                 = value.namespace != null ? value.namespace : var.namespace
      time_trigger                                              = value.time_trigger != null ? value.time_trigger : var.time_trigger
      expiration_delta_in_days                                  = value.expiration_delta_in_days != null ? value.expiration_delta_in_days : var.expiration_delta_in_days
      keyvault_name                                             = value.keyvault_name != null ? value.keyvault_name : var.keyvault_name
      keyvault_tenant_id                                        = value.keyvault_tenant_id != null ? value.keyvault_tenant_id : var.keyvault_tenant_id
      kv_secret_name_for_application_insights_connection_string = value.kv_secret_name_for_application_insights_connection_string != null ? value.kv_secret_name_for_application_insights_connection_string : var.kv_secret_name_for_application_insights_connection_string
      service_account_name                                      = value.service_account_name != null ? value.service_account_name : var.workload_identity_service_account_name
      workload_identity_client_id                               = value.workload_identity_client_id != null ? value.workload_identity_client_id : var.workload_identity_client_id
      helm_chart_present                                        = value.helm_chart_present != null ? value.helm_chart_present : var.helm_chart_present
      helm_chart_version                                        = value.helm_chart_version != null ? value.helm_chart_version : var.helm_chart_version
      helm_chart_image_name                                     = value.helm_chart_image_name != null ? value.helm_chart_image_name : var.helm_chart_image_name
      helm_chart_image_tag                                      = value.helm_chart_image_tag != null ? value.helm_chart_image_tag : var.helm_chart_image_tag
      alert_enabled                                             = value.alert_enabled != null ? value.alert_enabled : var.alert_enabled
      application_insights_resource_group                       = value.application_insights_resource_group != null ? value.application_insights_resource_group : var.application_insights_resource_group
      application_insights_id                                   = value.application_insights_id != null ? value.application_insights_id : var.application_insights_id
      application_insights_action_group_ids                     = value.application_insights_action_group_ids != null ? value.application_insights_action_group_ids : var.application_insights_action_group_ids
      pod_ram                                                   = value.pod_ram != null ? value.pod_ram : var.pod_ram
      pod_cpu                                                   = value.pod_cpu != null ? value.pod_cpu : var.pod_cpu
      tolerations                                               = value.tolerations != null ? value.tolerations : var.tolerations
      affinity                                                  = value.affinity != null ? value.affinity : var.affinity
      cert_mounter_chart_version                                = value.cert_mounter_chart_version != null ? value.cert_mounter_chart_version : var.cert_mounter_chart_version
      release_name = (
        value.release_name != null ? value.release_name :
        key == local.certificate_default_key ? var.helm_release_name : "${var.helm_release_name}-${key}"
      )
    }
  }

  # Entries whose TLS checker is actually deployed; helm_release does not accept for_each
  # entries that should be skipped.
  certificates_with_chart = {
    for key, value in local.certificates : key => value if value.helm_chart_present
  }

  tls_checker_alert_names = {
    for key, value in local.certificates : key => value.alert_name != null ? lower(replace(value.alert_name, "/\\W/", "-")) : lower(replace(value.https_endpoint, "/\\W/", "-"))
  }

  # all this work is mandatory to avoid helm name limit of 53 chars
  tls_checker_helm_chart_names = {
    for key, value in local.certificates : key => "${lower(substr(replace("chckr-${value.alert_name}", "/\\W/", "-"), 0, 47))}${substr(sha256(value.alert_name), 0, 5)}"
  }
}
