###############################################################################
# Namespace
###############################################################################

resource "kubernetes_namespace_v1" "haproxy_ingress" {
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
    namespace = kubernetes_namespace_v1.haproxy_ingress.metadata[0].name
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
      {
        name  = "controller.replicaCount"
        value = tostring(var.replica_count)
      },
      {
        name  = "controller.image.tag"
        value = var.controller_image_tag
      },
      {
        name  = "controller.resources.requests.cpu"
        value = var.resources.requests_cpu
      },
      {
        name  = "controller.resources.requests.memory"
        value = var.resources.requests_memory
      },
      {
        name  = "controller.resources.limits.cpu"
        value = var.resources.limits_cpu
      },
      {
        name  = "controller.resources.limits.memory"
        value = var.resources.limits_memory
      },
      {
        name  = "controller.service.type"
        value = var.service_type
      },
      {
        name  = "controller.autoscaling.enabled"
        value = tostring(var.autoscaling.enabled)
      },
      {
        name  = "controller.autoscaling.minReplicas"
        value = tostring(var.autoscaling.min_replicas)
      },
      {
        name  = "controller.autoscaling.maxReplicas"
        value = tostring(var.autoscaling.max_replicas)
      },
      {
        name  = "controller.autoscaling.targetCPUUtilizationPercentage"
        value = tostring(var.autoscaling.target_cpu_utilization)
      },
      {
        name  = "controller.autoscaling.targetMemoryUtilizationPercentage"
        value = tostring(var.autoscaling.target_memory_utilization)
      },
      {
        name  = "controller.podDisruptionBudget.enable"
        value = tostring(var.pod_disruption_budget.enabled)
      },
      {
        name  = "controller.podDisruptionBudget.minAvailable"
        value = tostring(var.pod_disruption_budget.min_available)
      },
      {
        name  = "controller.podAntiAffinity"
        value = "true"
      },
      {
        name  = "controller.podAntiAffinityTopologyKey"
        value = var.anti_affinity_topology_key
      },
      {
        name  = "controller.securityContext.runAsNonRoot"
        value = "true"
      },
      {
        name  = "controller.securityContext.runAsUser"
        value = "1000"
      },
      {
        name  = "controller.securityContext.allowPrivilegeEscalation"
        value = "false"
      },
      {
        name  = "controller.securityContext.readOnlyRootFilesystem"
        value = "true"
      },
      {
        name  = "controller.securityContext.capabilities.drop[0]"
        value = "ALL"
      },
      {
        name  = "controller.containerSecurityContext.runAsNonRoot"
        value = "true"
      },
      {
        name  = "controller.stats.enabled"
        value = tostring(var.enable_stats)
      },
      {
        name  = "controller.metrics.enabled"
        value = tostring(var.enable_metrics)
      },
      {
        name  = "controller.metrics.port"
        value = tostring(var.metrics_port)
      },
      {
        name  = "controller.serviceMonitor.enabled"
        value = tostring(var.enable_service_monitor)
      },
      {
        name  = "controller.logging.level"
        value = var.log_level
      },
      {
        name  = "controller.ingressClass"
        value = var.ingress_class_name
      },
      {
        name  = "controller.ingressClassResource.name"
        value = var.ingress_class_name
      },
      {
        name  = "controller.ingressClassResource.enabled"
        value = "true"
      },
      {
        name  = "controller.ingressClassResource.default"
        value = tostring(var.set_as_default_ingress_class)
      }
    ],
    [for key, value in var.service_annotations : {
      name  = "controller.service.annotations.${key}"
      value = value
    }],
    var.load_balancer_ip != null ? [{
      name  = "controller.service.loadBalancerIP"
      value = var.load_balancer_ip
    }] : [],
    var.default_ssl_certificate != null ? [
      {
        name  = "controller.defaultTLSSecret.enabled"
        value = "true"
      },
      {
        name  = "controller.defaultTLSSecret.secret"
        value = var.default_ssl_certificate
      }
    ] : [],
    var.enable_topology_spread ? [
      {
        name  = "controller.topologySpreadConstraints[0].maxSkew"
        value = "1"
      },
      {
        name  = "controller.topologySpreadConstraints[0].topologyKey"
        value = "topology.kubernetes.io/zone"
      },
      {
        name  = "controller.topologySpreadConstraints[0].whenUnsatisfiable"
        value = "DoNotSchedule"
      }
    ] : [],
    [for key, value in var.extra_set_values : {
      name  = key
      value = value
    }]
  )
}

resource "kubernetes_network_policy_v1" "haproxy_ingress_default_deny" {
  count = var.enable_network_policy ? 1 : 0

  metadata {
    name      = "${var.release_name}-default-deny"
    namespace = kubernetes_namespace_v1.haproxy_ingress.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    egress {
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "haproxy_ingress_allow" {
  count = var.enable_network_policy ? 1 : 0

  metadata {
    name      = "${var.release_name}-allow-ingress"
    namespace = kubernetes_namespace_v1.haproxy_ingress.metadata[0].name
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
  name            = var.release_name
  repository      = "https://haproxytech.github.io/helm-charts"
  chart           = "kubernetes-ingress"
  version         = var.chart_version
  namespace       = kubernetes_namespace_v1.haproxy_ingress.metadata[0].name
  cleanup_on_fail = true
  atomic          = var.atomic
  wait            = true
  wait_for_jobs   = true
  timeout         = var.timeout_seconds
  recreate_pods   = false
  force_update    = false

  set = local.helm_set_values

  values = concat(
    var.extra_values_files,
    var.values_override != null ? [var.values_override] : []
  )

  depends_on = [
    kubernetes_namespace_v1.haproxy_ingress,
    kubernetes_resource_quota_v1.haproxy_ingress,
  ]
}

moved {
  from = kubernetes_namespace.haproxy_ingress
  to   = kubernetes_namespace_v1.haproxy_ingress
}

moved {
  from = kubernetes_resource_quota.haproxy_ingress
  to   = kubernetes_resource_quota_v1.haproxy_ingress
}

moved {
  from = kubernetes_network_policy.haproxy_ingress_default_deny
  to   = kubernetes_network_policy_v1.haproxy_ingress_default_deny
}

moved {
  from = kubernetes_network_policy.haproxy_ingress_allow
  to   = kubernetes_network_policy_v1.haproxy_ingress_allow
}

