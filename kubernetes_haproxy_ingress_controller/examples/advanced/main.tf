###############################################################################
# ADVANCED example - HAProxy Ingress on AKS
# Production-grade configuration with:
#   - Internal Load Balancer + static IP
#   - Default TLS certificate
#   - ServiceMonitor for Prometheus Operator
#   - Topology spread across availability zones
#   - Network Policy
#   - Default IngressClass
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0, < 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

###############################################################################
# HAProxy Ingress module - production configuration
###############################################################################

module "haproxy_ingress" {
  source = "../../"

  release_name  = "haproxy-ingress"
  namespace     = "haproxy-ingress"
  chart_version = "1.40.0"

  # ---- Namespace labels for Azure Policy / Workload Identity ----
  namespace_labels = {
    "azure.workload.identity/use" = "false"
    "environment"                 = var.environment
  }

  # ---- Replicas & aggressive autoscaling ----
  replica_count = 3

  autoscaling = {
    enabled                   = true
    min_replicas              = 3
    max_replicas              = 20
    target_cpu_utilization    = 70
    target_memory_utilization = 75
  }

  # ---- PDB: keep at least 2 pods always available ----
  pod_disruption_budget = {
    enabled       = true
    min_available = 2
  }

  # ---- Resources (production sizing) ----
  resources = {
    requests_cpu    = "200m"
    requests_memory = "256Mi"
    limits_cpu      = "1000m"
    limits_memory   = "1Gi"
  }

  # ---- Resource Quota on the namespace ----
  enable_resource_quota = true
  namespace_quota = {
    requests_cpu    = "8"
    requests_memory = "8Gi"
    limits_cpu      = "16"
    limits_memory   = "16Gi"
    pods            = "50"
  }

  # ---- Internal Load Balancer with static IP ----
  service_type     = "LoadBalancer"
  load_balancer_ip = var.static_lb_ip

  service_annotations = {
    # Force the Load Balancer to be internal to the VNet
    "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
    # Dedicated subnet for the Load Balancer (optional)
    "service.beta.kubernetes.io/azure-load-balancer-internal-subnet" = var.lb_subnet_name
  }

  # ---- Default IngressClass ----
  ingress_class_name           = "haproxy"
  set_as_default_ingress_class = true

  # ---- Wildcard TLS certificate managed by cert-manager ----
  default_ssl_certificate = "haproxy-ingress/wildcard-tls"

  # ---- Full monitoring ----
  enable_metrics         = true
  enable_stats           = true
  enable_service_monitor = true # requires Prometheus Operator to be installed
  metrics_port           = 1024

  # ---- Network Policy ----
  enable_network_policy = true

  # ---- Distribution across Azure availability zones (zones 1, 2, 3) ----
  enable_topology_spread     = true
  anti_affinity_topology_key = "topology.kubernetes.io/zone"

  # ---- Logging ----
  log_level = "info"

  # ---- Generous timeout for environments with slow policies ----
  timeout_seconds = 600
  atomic          = true

  # ---- Targeted overrides for advanced HAProxy settings ----
  extra_set_values = {
    "controller.config.ssl-redirect"           = "true"
    "controller.config.timeout-connect"        = "5s"
    "controller.config.timeout-client"         = "50s"
    "controller.config.timeout-server"         = "50s"
    "controller.config.nbthread"               = "4"
    "controller.config.max-spread-checks"      = "10"
    "controller.config.forwarded-for"          = "true"
    "controller.config.load-balance"           = "roundrobin"
    "controller.config.rate-limit-status-code" = "429"
  }
}

###############################################################################
# Output
###############################################################################

output "ingress_namespace" {
  value = module.haproxy_ingress.namespace
}

output "ingress_class" {
  value = module.haproxy_ingress.ingress_class_name
}

output "release_status" {
  value = module.haproxy_ingress.release_status
}
