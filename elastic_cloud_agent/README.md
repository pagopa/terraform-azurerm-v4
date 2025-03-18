# Elastic Agent for elastic cloud

This module deploys an elastic agent in a given aks cluster

## Configurations

## How to use it

TODO

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.19.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.agent_namespace](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.cluster_role](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.cluster_role_binding](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.config_map](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.daemon_set](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.elastic_agent_kubeadmin_role](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.elastic_agent_kubeadmin_role_binding](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.elastic_agent_role](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.elastic_agent_role_binding](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.secret_api_key](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.service_account](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apm_integration_policy"></a> [apm\_integration\_policy](#input\_apm\_integration\_policy) | Details of the 'apm' integration policy in elasticsearch | <pre>object({<br/>    name = string<br/>    id   = string<br/>  })</pre> | n/a | yes |
| <a name="input_apm_package_version"></a> [apm\_package\_version](#input\_apm\_package\_version) | Version of the 'apm' integration package | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | If true creates the namespace used by elastic-agent, expects it to be created otherwise | `bool` | `true` | no |
| <a name="input_dedicated_log_instance_name"></a> [dedicated\_log\_instance\_name](#input\_dedicated\_log\_instance\_name) | List of namespaces or pod names for which the logs will be collected by the elastic agent | `list(string)` | n/a | yes |
| <a name="input_elastic_agent_kube_namespace"></a> [elastic\_agent\_kube\_namespace](#input\_elastic\_agent\_kube\_namespace) | Namespace where to install the elastic agent resources | `string` | n/a | yes |
| <a name="input_elasticsearch_api_key"></a> [elasticsearch\_api\_key](#input\_elasticsearch\_api\_key) | Api key used by the elastic agent | `string` | n/a | yes |
| <a name="input_elasticsearch_host"></a> [elasticsearch\_host](#input\_elasticsearch\_host) | Host where the elastic agent will send the collected logs/metrics | `string` | n/a | yes |
| <a name="input_k8s_integration_policy"></a> [k8s\_integration\_policy](#input\_k8s\_integration\_policy) | Details of the 'kubernetes' integration policy in elasticsearch | <pre>object({<br/>    name = string<br/>    id   = string<br/>  })</pre> | n/a | yes |
| <a name="input_k8s_package_version"></a> [k8s\_package\_version](#input\_k8s\_package\_version) | Version of the 'kubernetes' integration package | `string` | n/a | yes |
| <a name="input_system_integration_policy"></a> [system\_integration\_policy](#input\_system\_integration\_policy) | Details of the 'system' integration policy in elasticsearch | <pre>object({<br/>    name = string<br/>    id   = string<br/>  })</pre> | n/a | yes |
| <a name="input_system_package_version"></a> [system\_package\_version](#input\_system\_package\_version) | Version of the 'system' integration package | `string` | n/a | yes |
| <a name="input_target"></a> [target](#input\_target) | Identifier of a target within an elastic deployment, such as 'pagopa-dev' or 'arc-uat' | `string` | n/a | yes |
| <a name="input_target_namespace"></a> [target\_namespace](#input\_target\_namespace) | Identifier of a target within an elastic deployment, expressed in an elastic namespace format, such as 'pagopa.dev' or 'arc.uat' | `string` | n/a | yes |
| <a name="input_tolerated_taints"></a> [tolerated\_taints](#input\_tolerated\_taints) | List of tolerated taint keys. Optionally 'effect' can be defined | <pre>list(object({<br/>    key    = string<br/>    effect = optional(string, "NoSchedule")<br/>  }))</pre> | `[]` | no |
| <a name="input_unmanaged_prometheus_namespace"></a> [unmanaged\_prometheus\_namespace](#input\_unmanaged\_prometheus\_namespace) | Namespace where the prometheus-kube-state-metrics is installed | `string` | n/a | yes |
| <a name="input_use_managed_prometheus"></a> [use\_managed\_prometheus](#input\_use\_managed\_prometheus) | If true, the elastic agent will use the managed prometheus instance (ama metrics) to retrieve metrics, otherwise it will use the prometheus-kube-state-metrics instance | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
