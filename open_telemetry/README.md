# Open telemetry controller and collector

This module deploys an otel manager and otel collector in the given cluster

## Configurations

## How to use it

```hcl
# variables example

aks_config = [
  {
    name = "pagopa-u-weu-uat-aks"
    otel = {
      namespace = "elastic-system"
      create_ns = false
    }
  }
]

sampling_configuration = {
    enabled                    = true
    probes_sampling_percentage = 10
    sampling_percentage        = 50
    probe_paths = ["/actuator/health/liveness", "/actuator/health/readiness", "/actuator/health/{*path}", "/health/liveness", "/health/readiness"]
}

# module usage example
module "otel_collector" {
  source = "./.terraform/modules/__v4__/open_telemetry"

  elasticsearch_api_key               = data.azurerm_key_vault_secret.elasticsearch_api_key.value
  elasticsearch_apm_host              = data.ec_deployment.deployment.integrations_server[0].https_endpoint
  opentelemetry_operator_helm_version = var.opentelemetry_operator_helm_version
  otel_kube_namespace                 = var.aks_config[0].otel.namespace
  create_namespace                    = var.aks_config[0].otel.create_ns
  grpc_receiver_port                  = var.aks_config[0].otel.receiver_port
  deployment_env                      = var.env
  elastic_namespace                   = "${var.prefix}.${var.env}"

  affinity_selector = var.aks_config[0].otel.affinity_selector
  
  sampling = var.sampling_configuration
}
```
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
| <a name="input_sampling"></a> [sampling](#input\_sampling) | Sampling configuration for the OpenTelemetry collector traces | <pre>object({<br/>    enabled                    = bool<br/>    probes_sampling_percentage = optional(number, 1)<br/>    sampling_percentage        = optional(number, 50)<br/>    probe_paths                = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "probe_paths": [],<br/>  "probes_sampling_percentage": 1,<br/>  "sampling_percentage": 50<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
