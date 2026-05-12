###############################################################################
# Namespace
###############################################################################

resource "kubernetes_namespace_v1" "haproxy_ingress" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/component"  = "ingress"
      },
      var.namespace_labels
    )

    annotations = merge(
      {
        "meta.helm.sh/release-name"      = var.release_name
        "meta.helm.sh/release-namespace" = var.namespace
      },
      var.namespace_annotations
    )
  }
}

###############################################################################
# Resource Quota
###############################################################################

resource "kubernetes_resource_quota_v1" "haproxy_ingress" {
  count = var.enable_resource_quota ? 1 : 0

  metadata {
    name      = "${var.release_name}-quota"
    namespace = kubernetes_namespace_v1.haproxy_ingress.0.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.namespace_quota.requests_cpu
      "requests.memory" = var.namespace_quota.requests_memory
      "limits.cpu"      = var.namespace_quota.limits_cpu
      "limits.memory"   = var.namespace_quota.limits_memory
      "pods"            = var.namespace_quota.pods
    }
  }
}

###############################################################################
# Network Policy
###############################################################################

locals {
  helm_set_values = concat(
    [
      { name = "controller.replicaCount", value = tostring(var.replica_count), type = "auto" },
      { name = "controller.autoscaling.minReplicas", value = tostring(var.autoscaling.min_replicas), type = "auto" },
      { name = "controller.autoscaling.maxReplicas", value = tostring(var.autoscaling.max_replicas), type = "auto" },
      { name = "controller.autoscaling.targetCPUUtilizationPercentage", value = tostring(var.autoscaling.target_cpu_utilization), type = "auto" },
      { name = "controller.autoscaling.targetMemoryUtilizationPercentage", value = tostring(var.autoscaling.target_memory_utilization), type = "auto" },
      { name = "controller.podDisruptionBudget.minAvailable", value = tostring(var.pod_disruption_budget.min_available), type = "auto" },
      { name = "controller.securityContext.runAsUser", value = "1000", type = "auto" },
      { name = "controller.metrics.port", value = tostring(var.metrics_port), type = "auto" },
      { name = "controller.image.tag", value = var.controller_image_tag, type = "string" },
      { name = "controller.resources.requests.cpu", value = var.resources.requests_cpu, type = "string" },
      { name = "controller.resources.requests.memory", value = var.resources.requests_memory, type = "string" },
      { name = "controller.resources.limits.cpu", value = var.resources.limits_cpu, type = "string" },
      { name = "controller.resources.limits.memory", value = var.resources.limits_memory, type = "string" },
      { name = "controller.service.type", value = var.service_type, type = "string" },
      { name = "controller.autoscaling.enabled", value = tostring(var.autoscaling.enabled), type = "string" },
      { name = "controller.podDisruptionBudget.enable", value = tostring(var.pod_disruption_budget.enabled), type = "string" },
      { name = "controller.podAntiAffinity", value = "true", type = "string" },
      { name = "controller.podAntiAffinityTopologyKey", value = var.anti_affinity_topology_key, type = "string" },
      { name = "controller.securityContext.runAsNonRoot", value = "true", type = "string" },
      { name = "controller.securityContext.allowPrivilegeEscalation", value = "false", type = "string" },
      { name = "controller.securityContext.readOnlyRootFilesystem", value = "true", type = "string" },
      { name = "controller.securityContext.capabilities.drop[0]", value = "ALL", type = "string" },
      { name = "controller.containerSecurityContext.runAsNonRoot", value = "true", type = "string" },
      { name = "controller.stats.enabled", value = tostring(var.enable_stats), type = "string" },
      { name = "controller.metrics.enabled", value = tostring(var.enable_metrics), type = "string" },
      { name = "controller.serviceMonitor.enabled", value = tostring(var.enable_service_monitor), type = "string" },
      { name = "controller.logging.level", value = var.log_level, type = "string" },
      { name = "controller.ingressClass", value = var.ingress_class_name, type = "string" },
      { name = "controller.ingressClassResource.name", value = var.ingress_class_name, type = "string" },
      { name = "controller.ingressClassResource.enabled", value = "true", type = "string" },
      { name = "controller.ingressClassResource.default", value = tostring(var.set_as_default_ingress_class), type = "string" },
    ],
    [for key, value in merge(
      {
        "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
      },
      var.service_annotations
      ) : {
      name  = "controller.service.annotations.${replace(replace(key, ".", "\\."), "/", "\\/")}"
      value = value
      type  = "string"
    }],
    var.load_balancer_ip != null ? [{
      name  = "controller.service.loadBalancerIP"
      value = var.load_balancer_ip
      type  = "string"
    }] : [],
    var.default_ssl_certificate != null ? [
      { name = "controller.defaultSSLCertificate", value = var.default_ssl_certificate, type = "string" },
    ] : [],
    var.enable_topology_spread ? [
      { name = "controller.topologySpreadConstraints[0].maxSkew", value = "1", type = "auto" },
      { name = "controller.topologySpreadConstraints[0].topologyKey", value = "topology.kubernetes.io/zone", type = "string" },
      { name = "controller.topologySpreadConstraints[0].whenUnsatisfiable", value = "DoNotSchedule", type = "string" },
    ] : [],
    [for key, value in var.extra_set_values : {
      name  = key
      value = value
      type  = "string"
    }]
  )
}

resource "kubernetes_network_policy_v1" "haproxy_ingress_allow" {
  count = var.enable_network_policy ? 1 : 0

  metadata {
    name      = "${var.release_name}-allow-ingress"
    namespace = kubernetes_namespace_v1.haproxy_ingress.0.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "haproxy-ingress"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
      ports {
        port     = "8443"
        protocol = "TCP"
      }
    }

    # Prometheus scraping
    ingress {
      ports {
        port     = tostring(var.metrics_port)
        protocol = "TCP"
      }
    }

    egress {}
  }
}

###############################################################################
# Helm Release - HAProxy Ingress Controller
###############################################################################

resource "helm_release" "haproxy_ingress" {
  name          = var.release_name
  repository    = "https://haproxytech.github.io/helm-charts"
  chart         = "kubernetes-ingress"
  version       = var.chart_version
  namespace     = kubernetes_namespace_v1.haproxy_ingress.0.metadata[0].name
  atomic        = var.atomic
  wait          = true
  wait_for_jobs = true
  timeout       = var.timeout_seconds
  recreate_pods = false
  force_update  = false

  dynamic "set" {
    for_each = local.helm_set_values
    iterator = helm_set
    content {
      name  = helm_set.value["name"]
      value = helm_set.value["value"]
      type  = helm_set.value["type"]
    }
  }

  values = concat(
    var.extra_values_files,
    var.values_override != null ? [var.values_override] : []
  )

  depends_on = [
    kubernetes_namespace_v1.haproxy_ingress[0],
    kubernetes_resource_quota_v1.haproxy_ingress,
  ]
}
