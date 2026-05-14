###############################################################################
# BASIC example - HAProxy Ingress on AKS
# Minimal configuration for a development/staging cluster.
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

# Retrieve credentials from the existing AKS cluster
data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

###############################################################################
# HAProxy Ingress module - basic configuration
###############################################################################

module "haproxy_ingress" {
  source = "../../" # point to the local module or the registry

  release_name  = "haproxy-ingress"
  namespace     = "haproxy-ingress"
  chart_version = "1.40.0"

  # 2 replicas for basic high availability
  replica_count = 2

  # Basic autoscaling
  autoscaling = {
    enabled                   = true
    min_replicas              = 2
    max_replicas              = 5
    target_cpu_utilization    = 75
    target_memory_utilization = 80
  }

  # Public LoadBalancer Service
  service_type = "LoadBalancer"

  # Metrics enabled
  enable_metrics = true
  enable_stats   = true
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
