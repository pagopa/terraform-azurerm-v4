# Open Telemetry Controller and Collector

This module deploys an OpenTelemetry Operator (via Helm) and an OpenTelemetry Collector on an existing AKS cluster, configured to forward APM traces to an Elastic APM endpoint. It supports tail-based sampling, probe-path filtering, memory limiting, and optional namespace creation.

## Description

The module provisions the following Kubernetes resources:

- **Namespace** _(optional)_: A dedicated Kubernetes namespace for the OpenTelemetry components, created only when `create_namespace = true`.
- **Helm Release**: The `opentelemetry-operator` Helm chart from the official OpenTelemetry Helm repository, with optional node affinity configuration.
- **OpenTelemetryCollector**: A `kubectl_manifest` resource that deploys an `OpenTelemetryCollector` custom resource (CRD) in `deployment` mode, wired with:
  - An OTLP gRPC receiver on a configurable port
  - A memory limiter processor
  - Tail-based sampling (with per-path probe sampling overrides)
  - An OTLP/HTTP exporter targeting Elastic APM

## Usage

```hcl
module "otel_collector" {
  source = "./.terraform/modules/__v4__/open_telemetry"

  # Required
  elasticsearch_api_key               = data.azurerm_key_vault_secret.elasticsearch_api_key.value
  elasticsearch_apm_host              = data.ec_deployment.deployment.integrations_server[0].https_endpoint
  opentelemetry_operator_helm_version = "0.58.0"
  otel_kube_namespace                 = "elastic-system"
  deployment_env                      = var.env

  # Optional
  create_namespace   = true                   # optional, default: true
  grpc_receiver_port = 4317                   # optional, default: 4317
  elastic_namespace  = "myprefix.uat"         # optional, default: "default"
  affinity_selector  = null                   # optional, default: null

  sampling = {                                # optional — sampling disabled by default
    enabled                    = false
    probes_sampling_percentage = 1
    sampling_percentage        = 50
    probe_paths                = []
  }

  otlp_exporter_config = {                   # optional — sensible defaults provided
    queue_size       = 1000
    consumers        = 10
    memory_limit_mib = 2000
  }
}
```

## Examples

### Minimal — sampling disabled, namespace pre-existing

```hcl
module "otel_collector" {
  source = "./.terraform/modules/__v4__/open_telemetry"

  elasticsearch_api_key               = data.azurerm_key_vault_secret.elasticsearch_api_key.value
  elasticsearch_apm_host              = data.ec_deployment.deployment.integrations_server[0].https_endpoint
  opentelemetry_operator_helm_version = "0.75.0"
  otel_kube_namespace                 = "elastic-system"
  deployment_env                      = "uat"

  create_namespace = false # namespace already exists in the cluster
}
```

### Full — sampling enabled, affinity, custom OTLP exporter tuning

```hcl
module "otel_collector" {
  source = "./.terraform/modules/__v4__/open_telemetry"

  elasticsearch_api_key               = data.azurerm_key_vault_secret.elasticsearch_api_key.value
  elasticsearch_apm_host              = data.ec_deployment.deployment.integrations_server[0].https_endpoint
  opentelemetry_operator_helm_version = "0.75.0"
  otel_kube_namespace                 = "elastic-system"
  deployment_env                      = "prod"
  elastic_namespace                   = "myprefix.prod"
  create_namespace                    = true
  grpc_receiver_port                  = 4317

  affinity_selector = {
    key   = "node-type"
    value = "monitoring"
  }

  sampling = {
    enabled                    = true
    sampling_percentage        = 20
    probes_sampling_percentage = 5
    probe_paths = [
      "/actuator/health/liveness",
      "/actuator/health/readiness",
      "/actuator/health/{*path}",
      "/health/liveness",
      "/health/readiness"
    ]
  }

  otlp_exporter_config = {
    queue_size       = 2000
    consumers        = 20
    memory_limit_mib = 4000
  }
}
```

## Notes

- **Helm version constraint**: `opentelemetry_operator_helm_version` must follow SemVer (`X.Y.Z`) and the chart version must be `>= 0.58.0`. Older versions are rejected by a built-in Terraform validation rule.
- **Sensitive variable**: `elasticsearch_api_key` is marked as `sensitive = true`. Always source this value from Azure Key Vault (e.g. via `data.azurerm_key_vault_secret`) and never hardcode it.
- **Namespace lifecycle**: Set `create_namespace = true` (the default) to let the module create the Kubernetes namespace. If the namespace already exists in the cluster, set it to `false` to avoid conflicts.
- **Affinity**: `affinity_selector` defaults to `null` (no affinity rules applied). When provided, node affinity is applied to both the operator manager and the collector pods via `requiredDuringSchedulingIgnoredDuringExecution`.
- **Tail-based sampling**: When `sampling.enabled = true`, the collector applies tail-based sampling across all traces. Errors (`status_code = ERROR`) are **always** sampled regardless of the configured percentage. Probe paths listed in `probe_paths` are sampled at `probes_sampling_percentage`, while all other traces are sampled at `sampling_percentage`.
- **Provider requirements**: A pre-configured `helm` provider (pointing to the target AKS cluster) and a `kubectl` provider are required in the calling module. These are not configured by this module.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.17.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.19.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.opentelemetry_operator_helm](https://registry.terraform.io/providers/hashicorp/helm/2.17.0/docs/resources/release) | resource |
| [kubectl_manifest.agent_namespace](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.otel_collector](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_affinity_selector"></a> [affinity\_selector](#input\_affinity\_selector) | Affinity selector configuration for opentelemetry pods | <pre>object({<br/>    key   = string<br/>    value = string<br/>  })</pre> | `null` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | If true creates the namespace used by otel, expects it to be created otherwise | `bool` | `true` | no |
| <a name="input_deployment_env"></a> [deployment\_env](#input\_deployment\_env) | Deployment.environment tag value | `string` | n/a | yes |
| <a name="input_elastic_namespace"></a> [elastic\_namespace](#input\_elastic\_namespace) | Elastic namespace used to store the apm data. defaults to 'default' | `string` | `"default"` | no |
| <a name="input_elasticsearch_api_key"></a> [elasticsearch\_api\_key](#input\_elasticsearch\_api\_key) | Api key used by the elastic agent | `string` | n/a | yes |
| <a name="input_elasticsearch_apm_host"></a> [elasticsearch\_apm\_host](#input\_elasticsearch\_apm\_host) | Host where the otel collector will send the collected apm | `string` | n/a | yes |
| <a name="input_grpc_receiver_port"></a> [grpc\_receiver\_port](#input\_grpc\_receiver\_port) | Otel collector grpc receiver port | `number` | `4317` | no |
| <a name="input_opentelemetry_operator_helm_version"></a> [opentelemetry\_operator\_helm\_version](#input\_opentelemetry\_operator\_helm\_version) | Helm chart version for otel operator | `string` | n/a | yes |
| <a name="input_otel_kube_namespace"></a> [otel\_kube\_namespace](#input\_otel\_kube\_namespace) | Namespace where to install the elastic agent resources | `string` | n/a | yes |
| <a name="input_otlp_exporter_config"></a> [otlp\_exporter\_config](#input\_otlp\_exporter\_config) | Configuration for the OTLP exporter | <pre>object({<br/>    queue_size       = optional(number, 1000)<br/>    consumers        = optional(number, 10)<br/>    memory_limit_mib = optional(number, 2000)<br/>  })</pre> | <pre>{<br/>  "consumers": 10,<br/>  "memory_limit_mib": 2000,<br/>  "queue_size": 1000<br/>}</pre> | no |
| <a name="input_sampling"></a> [sampling](#input\_sampling) | Sampling configuration for the OpenTelemetry collector traces | <pre>object({<br/>    enabled                    = bool<br/>    probes_sampling_percentage = optional(number, 1)<br/>    sampling_percentage        = optional(number, 50)<br/>    probe_paths                = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "probe_paths": [],<br/>  "probes_sampling_percentage": 1,<br/>  "sampling_percentage": 50<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
