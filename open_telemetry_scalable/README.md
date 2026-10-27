# Open Telemetry Scalable Collector

Horizontally scalable version of the [`open_telemetry`](../open_telemetry) module. It deploys OpenTelemetry collectors on an existing AKS cluster following the [scaling stateful collectors](https://opentelemetry.io/docs/collector/scaling/#scaling-stateful-collectors) guideline, so that **tail based sampling** keeps working with more than one pod.

## Description

Tail sampling needs every span of a trace to be processed by the same collector. For this reason the module deploys two tiers:

```
apps ──OTLP──▶ [ lb tier (Deployment, N pods) ] ──loadbalancing exporter (routing_key: traceID)──▶ [ sampling tier (StatefulSet, M pods) ] ──▶ Elastic APM
                      │
                      └── metrics / logs ─────────────────────────────────────────────────────────────────────────────────▶ Elastic APM
```

- **Load balancer tier** (`<collector_name>-lb`, `Deployment`): stateless entrypoint for applications. Traces are optionally head sampled and sent to the sampling tier with the `loadbalancing` exporter, using the `traceID` routing key and the DNS resolver on the headless service of the sampling tier (so new/removed pods are discovered automatically). Metrics and logs do not need sampling and are sent straight to Elastic.
- **Sampling tier** (`<collector_name>-sampling`, `StatefulSet`): runs the `tail_sampling` processor and exports to Elastic APM.
- **Operator** _(optional)_: `opentelemetry-operator` Helm release.
- **Namespace** _(optional)_.

## Running side by side with the legacy module

The module uses its own Terraform addresses (it is a separate module) and different Kubernetes names (`otel-scalable-lb`, `otel-scalable-sampling`, Helm release `opentelemetry-cloud-operator-scalable`), so adding it to a project does not touch nor destroy the legacy `open_telemetry` resources. The legacy collector `otel` keeps running until applications are moved to the new endpoint (see output `load_balancer_service_endpoint`).

The OpenTelemetry operator is cluster wide (CRDs, webhooks, cluster roles): **do not install it twice**. When the legacy module already installed it, set `install_operator = false` (and `create_namespace = false`, the default).

Suggested migration:
1. Add this module with `install_operator = false`, pointing to the same namespace.
2. Move applications gradually to `load_balancer_service_endpoint`.
3. When no application uses the legacy `otel-collector` service, remove the legacy module.
4. The operator is owned by the legacy module: removing it uninstalls the operator. Before that, move the Helm release into this module (`terraform state mv`) and set `install_operator = true`, or keep the legacy module until the operator is handled elsewhere.

## Usage

```hcl
module "otel_collector_scalable" {
  source = "./.terraform/modules/__v4__/open_telemetry_scalable"

  elasticsearch_api_key  = data.azurerm_key_vault_secret.elasticsearch_api_key.value
  elasticsearch_apm_host = data.ec_deployment.deployment.integrations_server[0].https_endpoint
  otel_kube_namespace    = "elastic-system"
  deployment_env         = var.env
  elastic_namespace      = "myprefix.uat"

  # the operator is already installed by the legacy module
  install_operator = false

  load_balancer = {
    replicas = 2
    resources = {
      requests = { cpu = "500m", memory = "1Gi" }
      limits   = { cpu = "1", memory = "2Gi" }
    }
  }

  sampling = {
    replicas = 3
    resources = {
      requests = { cpu = "1", memory = "5Gi" }
      limits   = { cpu = "2", memory = "5Gi" }
    }
    memory_limiter = {
      memory_limit_mib = 4096
      spike_limit_mib  = 1024
    }
  }

  tail_sampling = {
    probe_paths         = ["/health/live", "/health/ready"]
    sampling_percentage = 50
  }

  providers = {
    kubectl = kubectl.cluster_1
    helm    = helm.cluster_1
  }
}
```

## Notes

- Tail sampling `num_traces` and the memory limiter are **per sampling pod**: size the pods for `1/M` of the traffic.
- Changing `sampling.replicas` changes the trace → pod assignment (consistent hashing): traces in flight during the change may be sampled incompletely. Prefer scaling during low traffic.
- Scale the sampling tier by changing `sampling.replicas`; do not use an HPA on it unless you accept the same reshuffling.
- If a sampling pod is not ready yet, the `loadbalancing` exporter retries through its `sending_queue`; the queue size is configured with `otlp_exporter_config`.
- The sampling tier receiver is plain gRPC without TLS and is reachable inside the cluster only; restrict it with a NetworkPolicy if the cluster enforces them.
- The API key is rendered in the collector manifests, as in the legacy module.

## Troubleshooting

- **Traces appear incomplete or duplicated**: verify that the load balancer pods resolve every sampling pod (`kubectl logs <lb pod>` shows the resolved endpoints) and that applications send to the `-lb` service, not to the sampling one.
- **`no such host` in the lb logs**: the operator creates `<collector_name>-sampling-collector-headless`; check the service exists in the namespace and that the operator version is >= 0.58.0.
- **Helm release conflict / CRD already exists**: the operator is already installed, set `install_operator = false`.

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
| [kubectl_manifest.otel_collector_lb](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.otel_collector_sampling](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_affinity_selector"></a> [affinity\_selector](#input\_affinity\_selector) | Affinity selector configuration for the opentelemetry operator pods | <pre>object({<br/>    key   = string<br/>    value = string<br/>  })</pre> | `null` | no |
| <a name="input_collector_name"></a> [collector\_name](#input\_collector\_name) | Base name of the collectors. The load balancer tier is named '<collector\_name>-lb' and the tail sampling tier '<collector\_name>-sampling'. Must differ from the names used by the legacy module ('otel') | `string` | `"otel-scalable"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | If true creates the namespace used by otel, expects it to exist otherwise. Keep false when deploying side by side with the legacy 'open\_telemetry' module on the same namespace | `bool` | `false` | no |
| <a name="input_deployment_env"></a> [deployment\_env](#input\_deployment\_env) | Deployment.environment tag value | `string` | n/a | yes |
| <a name="input_elastic_namespace"></a> [elastic\_namespace](#input\_elastic\_namespace) | Elastic namespace used to store the apm data. defaults to 'default' | `string` | `"default"` | no |
| <a name="input_elasticsearch_api_key"></a> [elasticsearch\_api\_key](#input\_elasticsearch\_api\_key) | Api key used by the otel collector | `string` | n/a | yes |
| <a name="input_elasticsearch_apm_host"></a> [elasticsearch\_apm\_host](#input\_elasticsearch\_apm\_host) | Host where the otel collector will send the collected apm | `string` | n/a | yes |
| <a name="input_grpc_receiver_port"></a> [grpc\_receiver\_port](#input\_grpc\_receiver\_port) | Port of the grpc OTLP receiver exposed to applications by the load balancer tier | `number` | `4317` | no |
| <a name="input_head_sampling"></a> [head\_sampling](#input\_head\_sampling) | Head Sampling configuration of the load balancer tier (applied by trace id, so consistent across pods) | <pre>object({<br/>    enabled             = optional(bool, false)<br/>    sampling_percentage = optional(number, 75)<br/>  })</pre> | `{}` | no |
| <a name="input_install_operator"></a> [install\_operator](#input\_install\_operator) | If true installs the OpenTelemetry operator Helm release. Set to false when the operator is already installed on the cluster (e.g. by the legacy 'open\_telemetry' module): the operator is cluster-wide and cannot be installed twice | `bool` | `true` | no |
| <a name="input_load_balancer"></a> [load\_balancer](#input\_load\_balancer) | Stateless tier receiving telemetry from applications. It routes the spans of each trace to the same sampling pod (loadbalancing exporter, routing\_key traceID). 'resources.requests' and 'resources.limits' are maps like { cpu = "500m", memory = "1Gi" } | <pre>object({<br/>    replicas          = optional(number, 2)<br/>    resolver_interval = optional(string, "5s")<br/>    resolver_timeout  = optional(string, "1s")<br/>    resources = optional(object({<br/>      requests = optional(map(string))<br/>      limits   = optional(map(string))<br/>    }))<br/>    memory_limiter = optional(object({<br/>      memory_limit_mib = optional(number, 1024)<br/>      spike_limit_mib  = optional(number, 256)<br/>      check_interval   = optional(string, "1s")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_opentelemetry_operator_helm_version"></a> [opentelemetry\_operator\_helm\_version](#input\_opentelemetry\_operator\_helm\_version) | Helm chart version for otel operator. Required when 'install\_operator' is true | `string` | `null` | no |
| <a name="input_operator_helm_release_name"></a> [operator\_helm\_release\_name](#input\_operator\_helm\_release\_name) | Name of the operator Helm release, used only when 'install\_operator' is true | `string` | `"opentelemetry-cloud-operator-scalable"` | no |
| <a name="input_otel_kube_namespace"></a> [otel\_kube\_namespace](#input\_otel\_kube\_namespace) | Namespace where to install the OpenTelemetry resources | `string` | n/a | yes |
| <a name="input_otlp_exporter_config"></a> [otlp\_exporter\_config](#input\_otlp\_exporter\_config) | Configuration for the OTLP exporters and batch processors | <pre>object({<br/>    queue_size     = optional(number, 1000)<br/>    consumers      = optional(number, 10)<br/>    batch_timeout  = optional(string, "1s")<br/>    batch_size     = optional(number, 1024)<br/>    batch_max_size = optional(number, 2048)<br/>  })</pre> | `{}` | no |
| <a name="input_sampling"></a> [sampling](#input\_sampling) | Stateful tier (StatefulSet) performing the tail sampling. Each pod receives all the spans of the traces assigned to it. Changing 'replicas' reshuffles the trace assignment: traces in flight during the change may be sampled incompletely. 'resources.requests' and 'resources.limits' are maps like { cpu = "1", memory = "5Gi" } | <pre>object({<br/>    replicas = optional(number, 3)<br/>    resources = optional(object({<br/>      requests = optional(map(string))<br/>      limits   = optional(map(string))<br/>    }))<br/>    memory_limiter = optional(object({<br/>      memory_limit_mib = optional(number, 4096)<br/>      spike_limit_mib  = optional(number, 1024)<br/>      check_interval   = optional(string, "1s")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_sampling_receiver_port"></a> [sampling\_receiver\_port](#input\_sampling\_receiver\_port) | Port of the grpc OTLP receiver of the tail sampling tier, receives traffic from the load balancer tier only | `number` | `4317` | no |
| <a name="input_tail_sampling"></a> [tail\_sampling](#input\_tail\_sampling) | Tail Sampling configuration of the sampling tier | <pre>object({<br/>    enabled                    = optional(bool, true)<br/>    probes_sampling_percentage = optional(number, 1)<br/>    sampling_percentage        = optional(number, 50)<br/>    probe_paths                = optional(list(string), [])<br/>    num_traces                 = optional(number, 50000)<br/>    decision_wait              = optional(string, "30s")<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_collector_name"></a> [load\_balancer\_collector\_name](#output\_load\_balancer\_collector\_name) | Name of the OpenTelemetryCollector resource of the load balancer tier |
| <a name="output_load_balancer_service_endpoint"></a> [load\_balancer\_service\_endpoint](#output\_load\_balancer\_service\_endpoint) | In-cluster OTLP gRPC endpoint (host:port) applications must send telemetry to |
| <a name="output_sampling_collector_name"></a> [sampling\_collector\_name](#output\_sampling\_collector\_name) | Name of the OpenTelemetryCollector resource of the tail sampling tier |
| <a name="output_sampling_headless_hostname"></a> [sampling\_headless\_hostname](#output\_sampling\_headless\_hostname) | DNS name resolved by the load balancer tier to discover the sampling pods |
<!-- END_TF_DOCS -->
