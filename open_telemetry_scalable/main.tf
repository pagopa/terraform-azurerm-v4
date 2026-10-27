locals {
  lb_name       = "${var.collector_name}-lb"
  sampling_name = "${var.collector_name}-sampling"

  # The operator creates the headless service '<cr name>-collector-headless', whose DNS record lists every sampling pod
  sampling_headless_hostname = "${local.sampling_name}-collector-headless.${var.otel_kube_namespace}.svc.cluster.local"

  lb_resources       = var.load_balancer.resources
  sampling_resources = var.sampling.resources

  common_template_vars = {
    namespace      = var.otel_kube_namespace
    apm_api_key    = var.elasticsearch_api_key
    apm_endpoint   = var.elasticsearch_apm_host
    queue_size     = var.otlp_exporter_config.queue_size
    num_consumers  = var.otlp_exporter_config.consumers
    batch_timeout  = var.otlp_exporter_config.batch_timeout
    batch_size     = var.otlp_exporter_config.batch_size
    batch_max_size = var.otlp_exporter_config.batch_max_size
  }
}

resource "kubectl_manifest" "agent_namespace" {
  count = var.create_namespace ? 1 : 0

  yaml_body = (replace(replace(templatefile("${path.module}/yaml/namespace.yaml", {
    namespace = var.otel_kube_namespace
  }), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))
}

resource "helm_release" "opentelemetry_operator_helm" {
  count      = var.install_operator ? 1 : 0
  depends_on = [kubectl_manifest.agent_namespace]

  name       = var.operator_helm_release_name
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

# Stateful tier: tail sampling, every trace is handled by exactly one pod
resource "kubectl_manifest" "otel_collector_sampling" {
  depends_on = [
    kubectl_manifest.agent_namespace,
    helm_release.opentelemetry_operator_helm
  ]

  yaml_body = templatefile("${path.module}/yaml/collector_sampling.yaml", merge(local.common_template_vars, {
    name                           = local.sampling_name
    replicas                       = var.sampling.replicas
    receiver_port                  = var.sampling_receiver_port
    resource_configuration_enabled = local.sampling_resources != null
    requests                       = try(local.sampling_resources.requests, null)
    limits                         = try(local.sampling_resources.limits, null)
    sampling_enabled               = var.tail_sampling.enabled
    probes_sampling_percentage     = var.tail_sampling.probes_sampling_percentage
    sampling_percentage            = var.tail_sampling.sampling_percentage
    probe_paths                    = var.tail_sampling.probe_paths
    tail_sampling_num_traces       = var.tail_sampling.num_traces
    tail_sampling_decision_wait    = var.tail_sampling.decision_wait
    memory_limiter_limit_mib       = var.sampling.memory_limiter.memory_limit_mib
    memory_limiter_spike_limit_mib = var.sampling.memory_limiter.spike_limit_mib
    memory_limiter_check_interval  = var.sampling.memory_limiter.check_interval
  }))

  force_conflicts = true
  wait            = true
}

# Stateless tier: entrypoint for applications, routes spans by trace id to the sampling pods
resource "kubectl_manifest" "otel_collector_lb" {
  depends_on = [kubectl_manifest.otel_collector_sampling]

  yaml_body = templatefile("${path.module}/yaml/collector_lb.yaml", merge(local.common_template_vars, {
    name                             = local.lb_name
    replicas                         = var.load_balancer.replicas
    receiver_port                    = var.grpc_receiver_port
    resource_configuration_enabled   = local.lb_resources != null
    requests                         = try(local.lb_resources.requests, null)
    limits                           = try(local.lb_resources.limits, null)
    deployment_env                   = var.deployment_env
    elastic_namespace                = var.elastic_namespace
    probabilistic_sampler_enabled    = var.head_sampling.enabled
    probabilistic_sampler_percentage = var.head_sampling.sampling_percentage
    sampling_headless_hostname       = local.sampling_headless_hostname
    sampling_receiver_port           = var.sampling_receiver_port
    resolver_interval                = var.load_balancer.resolver_interval
    resolver_timeout                 = var.load_balancer.resolver_timeout
    memory_limiter_limit_mib         = var.load_balancer.memory_limiter.memory_limit_mib
    memory_limiter_spike_limit_mib   = var.load_balancer.memory_limiter.spike_limit_mib
    memory_limiter_check_interval    = var.load_balancer.memory_limiter.check_interval
  }))

  force_conflicts = true
  wait            = true
}
