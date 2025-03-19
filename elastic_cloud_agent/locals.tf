locals {
  logs_general_to_exclude_paths = distinct(flatten([
    for instance_name in var.dedicated_log_instance_name : "'/var/log/containers/${instance_name}-*.log'"
  ]))

  template_resolution_variables = {
    namespace                     = var.elastic_agent_kube_namespace
    dedicated_log_instance_name   = var.dedicated_log_instance_name
    logs_general_to_exclude_paths = local.logs_general_to_exclude_paths

    system_name            = var.system_integration_policy.name
    system_id              = var.system_integration_policy.id
    system_revision        = 1
    system_package_version = var.system_package_version

    kubernetes_name            = var.k8s_integration_policy.name
    kubernetes_id              = var.k8s_integration_policy.id
    kubernetes_revision        = 1
    kubernetes_package_version = var.k8s_package_version

    apm_name            = var.apm_integration_policy.name
    apm_id              = var.apm_integration_policy.id
    apm_revision        = 1
    apm_package_version = var.apm_package_version


    target           = var.target
    target_namespace = var.target_namespace

    elastic_host = var.elasticsearch_host

    elasticsearch_api_key = var.elasticsearch_api_key
    elastic_agent_version = "8.17.1"

    tolerated_taints = var.tolerated_taints
    prometheus_url   = var.use_managed_prometheus ? "ama-metrics-ksm.kube-system.svc.cluster.local:8080" : "prometheus-kube-state-metrics.${var.unmanaged_prometheus_namespace}.svc.cluster.local:8080"
  }


}

