# Terraform Module — HAProxy Ingress Controller for AKS

Production-ready Terraform module to install **HAProxy Kubernetes Ingress Controller** on an **Azure Kubernetes Service (AKS)** cluster, following recommended best practices.

---

## Included features

| Feature | Description |
|---|---|
| **Dedicated namespace** | Isolated namespace with customizable labels and annotations |
| **Resource Quota** | Namespace-level CPU/memory/pod quotas to prevent resource starvation |
| **HPA (Horizontal Pod Autoscaler)** | Automatic scaling between min/max replicas based on CPU and memory |
| **Pod Disruption Budget** | Ensures a minimum number of pods remain available during node draining |
| **Security Context** | `runAsNonRoot`, `readOnlyRootFilesystem`, `capabilities.drop = ["ALL"]` |
| **Pod Anti-Affinity** | Spreads pods across different nodes |
| **Topology Spread Constraints** | Spreads pods across Azure Availability Zones |
| **Network Policy** | Default-deny plus selective allow rules for HTTP/HTTPS and Prometheus traffic |
| **Prometheus metrics** | `/metrics` endpoint plus ServiceMonitor support for Prometheus Operator |
| **IngressClass** | Registers a named IngressClass, optionally as the default |
| **Default TLS** | Supports wildcard certificates through cert-manager |
| **Internal Load Balancer** | Ready-to-use annotations for Azure Internal Load Balancer with static IP |
| **Atomic deploy** | Automatic Helm rollback if the deployment fails |

---

## Structure

```
terraform-aks-haproxy-ingress/
├── main.tf              # Main resources (Namespace, Helm, NetworkPolicy, Quota)
├── variables.tf         # All input variables
├── outputs.tf           # Module outputs
├── README.md
└── examples/
    ├── basic/           # Minimal setup (dev/staging)
    │   └── main.tf
    └── advanced/        # Production setup (internal LB, TLS, monitoring, AZ spread)
        └── main.tf
```

---

## Quick usage

### Basic

```hcl
module "haproxy_ingress" {
  source = "path/to/terraform-aks-haproxy-ingress"

  release_name  = "haproxy-ingress"
  namespace     = "haproxy-ingress"
  chart_version = "1.40.0"
  replica_count = 2
  service_type  = "LoadBalancer"
}
```

### Production (Internal LB + Monitoring)

```hcl
module "haproxy_ingress" {
  source = "path/to/terraform-aks-haproxy-ingress"

  chart_version = "1.40.0"
  replica_count = 3

  autoscaling = {
    enabled                   = true
    min_replicas              = 3
    max_replicas              = 20
    target_cpu_utilization    = 70
    target_memory_utilization = 75
  }

  pod_disruption_budget = {
    enabled       = true
    min_available = 2
  }

  service_type     = "LoadBalancer"
  load_balancer_ip = "10.0.1.100"

  service_annotations = {
    "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
  }

  set_as_default_ingress_class = true
  default_ssl_certificate      = "haproxy-ingress/wildcard-tls"
  enable_service_monitor       = true
  enable_topology_spread       = true
  enable_network_policy        = true
}
```

---

## Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `release_name` | string | `"haproxy-ingress"` | Helm release name |
| `namespace` | string | `"haproxy-ingress"` | Installation namespace |
| `chart_version` | string | `"1.40.0"` | Helm chart version |
| `controller_image_tag` | string | `"2.11.0"` | HAProxy image tag |
| `replica_count` | number | `2` | Replica count when HPA is disabled |
| `autoscaling` | object | see vars | HPA configuration |
| `pod_disruption_budget` | object | `{enabled=true, min_available=1}` | PDB configuration |
| `resources` | object | `100m/128Mi → 500m/512Mi` | CPU and memory requests/limits |
| `enable_resource_quota` | bool | `true` | Enables Resource Quota |
| `namespace_quota` | object | see vars | CPU/memory/pod quota settings |
| `service_type` | string | `"LoadBalancer"` | Kubernetes Service type |
| `service_annotations` | map | `{}` | Service annotations (for example Azure LB annotations) |
| `load_balancer_ip` | string | `null` | Static Load Balancer IP |
| `ingress_class_name` | string | `"haproxy"` | IngressClass name |
| `set_as_default_ingress_class` | bool | `false` | Sets the IngressClass as default |
| `default_ssl_certificate` | string | `null` | Wildcard TLS secret |
| `enable_metrics` | bool | `true` | Enables Prometheus metrics |
| `enable_stats` | bool | `true` | Enables the `/stats` endpoint |
| `metrics_port` | number | `1024` | Metrics port |
| `enable_service_monitor` | bool | `false` | Creates a ServiceMonitor |
| `enable_network_policy` | bool | `true` | Enables NetworkPolicy |
| `enable_topology_spread` | bool | `true` | Enables TopologySpreadConstraints |
| `anti_affinity_topology_key` | string | `"kubernetes.io/hostname"` | Anti-affinity topology key |
| `log_level` | string | `"info"` | Log level |
| `atomic` | bool | `true` | Enables automatic Helm rollback |
| `timeout_seconds` | number | `300` | Helm timeout |
| `extra_set_values` | map | `{}` | Targeted Helm value overrides |
| `extra_values_files` | list(string) | `[]` | Additional YAML values files |
| `values_override` | string | `null` | Full YAML override |

---

## Outputs

| Name | Description |
|---|---|
| `namespace` | Namespace where HAProxy Ingress Controller is installed. |
| `release_name` | Helm release name. |
| `release_status` | Helm release status. |
| `chart_version` | Installed Helm chart version. |
| `ingress_class_name` | IngressClass name registered by HAProxy. |
| `load_balancer_ip` | Assigned Load Balancer IP (if `service_type = LoadBalancer` and a static IP is configured). |
| `metrics_port` | Port on which HAProxy exposes Prometheus metrics. |

---

## Prerequisites

- Terraform `>= 1.5.0`
- Provider `hashicorp/kubernetes >= 2.23.0`
- Provider `hashicorp/helm >= 2.11.0`
- An existing and reachable AKS cluster
- (Optional) Prometheus Operator for `enable_service_monitor = true`
- (Optional) cert-manager for `default_ssl_certificate`
- (Optional) A CNI with NetworkPolicy support (for example Azure CNI + Calico / Cilium)

---

## Security notes

- The container runs as a non-root user (`runAsUser: 1000`)
- The root filesystem is read-only
- All Linux capabilities are dropped
- Network Policies block unauthorized traffic by default
- The namespace includes a Resource Quota to prevent resource starvation

---

## Advanced HAProxy configuration

Use `extra_set_values` for targeted HAProxy parameter overrides:

```hcl
extra_set_values = {
  "controller.config.ssl-redirect"    = "true"
  "controller.config.timeout-connect" = "5s"
  "controller.config.timeout-client"  = "50s"
  "controller.config.timeout-server"  = "50s"
  "controller.config.nbthread"        = "4"
  "controller.config.forwarded-for"   = "true"
}
```

For full overrides, use `values_override` with a YAML string.

---

## References

- [HAProxy Kubernetes Ingress Controller Docs](https://www.haproxy.com/documentation/kubernetes-ingress/)
- [Helm Chart haproxytech/kubernetes-ingress](https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress)
- [AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
