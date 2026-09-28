resource "kubectl_manifest" "agent_namespace" {
  count = var.create_namespace ? 1 : 0

  yaml_body = (replace(replace(templatefile("${path.module}/yaml/namespace.yaml", {
    namespace = var.otel_kube_namespace
  }), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))
}

resource "helm_release" "opentelemetry_operator_helm" {
  depends_on = [kubectl_manifest.agent_namespace]

  name       = "opentelemetry-cloud-operator"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  version    = var.opentelemetry_operator_helm_version
  namespace  = var.otel_kube_namespace


  values = [
    templatefile("${path.module}/yaml/values.yaml", {
      affinity_selector = var.affinity_selector
    })
  ]
}


resource "kubectl_manifest" "otel_collector" {
  depends_on = [
    helm_release.opentelemetry_operator_helm
  ]
  yaml_body = templatefile("${path.module}/yaml/collector.yaml", {
    namespace                        = var.otel_kube_namespace
    apm_api_key                      = var.elasticsearch_api_key
    apm_endpoint                     = var.elasticsearch_apm_host
    receiver_port                    = var.grpc_receiver_port
    deployment_env                   = var.deployment_env
    elastic_namespace                = var.elastic_namespace
    probes_sampling_percentage       = var.tail_sampling.probes_sampling_percentage
    sampling_percentage              = var.tail_sampling.sampling_percentage
    sampling_enabled                 = var.tail_sampling.enabled
    tail_sampling_num_traces         = var.tail_sampling.num_traces
    tail_sampling_decision_wait      = var.tail_sampling.decision_wait
    probe_paths                      = var.tail_sampling.probe_paths
    probabilistic_sampler_percentage = var.head_sampling.sampling_percentage
    probabilistic_sampler_enabled    = var.head_sampling.enabled
    queue_size                       = var.otlp_exporter_config.queue_size
    num_consumers                    = var.otlp_exporter_config.consumers
    memory_limiter_limit_mib         = var.memory_limiter.memory_limit_mib
    memory_limiter_spike_limit_mib   = var.memory_limiter.spike_limit_mib
    memory_limiter_check_interval    = var.memory_limiter.check_interval
    batch_timeout                    = var.otlp_exporter_config.batch_timeout
    batch_size                       = var.otlp_exporter_config.batch_size
    batch_max_size                   = var.otlp_exporter_config.batch_max_size
    resource_configuration_enabled   = var.resources != null
    cpu_limit                        = var.resources.limits.cpu
    cpu_request                      = var.resources.requests.cpu
  })

  force_conflicts = true
  wait            = true
}
