<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.12 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_metric_alert.alert_this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [helm_release.helm_cert_mounter_this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.helm_reloader_this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.helm_tls_checker_this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_affinity"></a> [affinity](#input\_affinity) | Pod Affinity and Anti-Affinity | `string` | `""` | no |
| <a name="input_alert_enabled"></a> [alert\_enabled](#input\_alert\_enabled) | (Optional) Is this alert enabled? | `bool` | `true` | no |
| <a name="input_alert_name"></a> [alert\_name](#input\_alert\_name) | (Optional) Alert name | `string` | `null` | no |
| <a name="input_application_insights_action_group_ids"></a> [application\_insights\_action\_group\_ids](#input\_application\_insights\_action\_group\_ids) | (Required) Application insights action group ids | `list(string)` | n/a | yes |
| <a name="input_application_insights_id"></a> [application\_insights\_id](#input\_application\_insights\_id) | (Required) Application Insights id | `string` | n/a | yes |
| <a name="input_application_insights_resource_group"></a> [application\_insights\_resource\_group](#input\_application\_insights\_resource\_group) | (Required) Application Insights resource group | `string` | n/a | yes |
| <a name="input_cert_mounter_chart_version"></a> [cert\_mounter\_chart\_version](#input\_cert\_mounter\_chart\_version) | (Optional) Cert mounter chart version | `string` | `"2.0.2"` | no |
| <a name="input_expiration_delta_in_days"></a> [expiration\_delta\_in\_days](#input\_expiration\_delta\_in\_days) | (Optional) | `string` | `"7"` | no |
| <a name="input_helm_chart_image_name"></a> [helm\_chart\_image\_name](#input\_helm\_chart\_image\_name) | Docker image name | `string` | `"ghcr.io/pagopa/infra-ssl-check"` | no |
| <a name="input_helm_chart_image_tag"></a> [helm\_chart\_image\_tag](#input\_helm\_chart\_image\_tag) | Docker image tag | `string` | `"v1.3.4@sha256:c3d45736706c981493b6216451fc65e99a69d5d64409ccb1c4ca93fef57c921d"` | no |
| <a name="input_helm_chart_present"></a> [helm\_chart\_present](#input\_helm\_chart\_present) | Is this helm chart present? | `bool` | `true` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Helm chart version for the tls checker application | `string` | `"7.6.0"` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | (Optional) Cert Mounter release name. Changed this field force the helm destroy and re-install | `string` | `"cert-mounter-blueprint"` | no |
| <a name="input_https_endpoint"></a> [https\_endpoint](#input\_https\_endpoint) | Https endpoint to check | `string` | n/a | yes |
| <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name) | (Required) Keyvault name | `string` | n/a | yes |
| <a name="input_keyvault_tenant_id"></a> [keyvault\_tenant\_id](#input\_keyvault\_tenant\_id) | (Required) Keyvault tenant id | `string` | n/a | yes |
| <a name="input_kv_secret_name_for_application_insights_connection_string"></a> [kv\_secret\_name\_for\_application\_insights\_connection\_string](#input\_kv\_secret\_name\_for\_application\_insights\_connection\_string) | (Required) The name of the secret inside the kv that contains the application insights connection string | `string` | n/a | yes |
| <a name="input_location_string"></a> [location\_string](#input\_location\_string) | (Required) Location string | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | (Required) Namespace where the helm chart will be installed | `string` | n/a | yes |
| <a name="input_pod_cpu"></a> [pod\_cpu](#input\_pod\_cpu) | Pod request and limit for CPU (in `m`) | `number` | `10` | no |
| <a name="input_pod_ram"></a> [pod\_ram](#input\_pod\_ram) | Pod request and limit for RAM memory (in `Mi`) | `number` | `30` | no |
| <a name="input_time_trigger"></a> [time\_trigger](#input\_time\_trigger) | cron trigger pattern | `string` | `"*/1 * * * *"` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Pod tolerations | `string` | `""` | no |
| <a name="input_workload_identity_client_id"></a> [workload\_identity\_client\_id](#input\_workload\_identity\_client\_id) | ClientID in form of 'qwerty123-a1aa-1234-xyza-qwerty123' linked to workload identity | `string` | `null` | no |
| <a name="input_workload_identity_service_account_name"></a> [workload\_identity\_service\_account\_name](#input\_workload\_identity\_service\_account\_name) | Service account name linked to workload identity | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->