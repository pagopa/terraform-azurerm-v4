# Kubernetes middleware
## Overview
This module deploys TLS monitoring and certificate-mounting middleware in an existing Kubernetes namespace, together with an Azure Monitor metric alert on an existing Application Insights resource.
It manages:
- A TLS checker using the [`microservice-chart`](https://pagopa.github.io/aks-microservice-chart-blueprint) Helm chart, enabled by default.
- The [`cert-mounter-blueprint`](https://pagopa.github.io/aks-helm-cert-mounter-blueprint) Helm chart, configured to retrieve the certificate named after the endpoint with dots replaced by hyphens.
- [Stakater Reloader](https://stakater.github.io/stakater-charts), pinned to chart version `v2.2.18`, with `reloader.watchGlobally = false`.
- An Application Insights availability metric alert, optionally connected to existing action groups.
The module does not create the cluster, namespace, Key Vault, Application Insights, action groups, managed identity or federated identity credentials. It does not expose any outputs.
## Prerequisites
- Terraform `>= 1.9.0`, `hashicorp/azurerm ~> 4` and `hashicorp/helm ~> 2.12`, as declared in `versions.tf`.
- Configure both providers in the calling configuration. AzureRM needs authentication for the target subscription and permission to manage the metric alert. Helm needs authenticated access to the target Kubernetes API and permission to install the charts. No Kubernetes provider is declared by this module.
- An existing namespace on a cluster configured for Azure Workload Identity, including its OIDC issuer and identity federation. The federated subject must match `system:serviceaccount:<namespace>:<workload_identity_service_account_name>`. Supply the managed identity's **client ID**, not its Azure resource ID.
- Key Vault access for that workload identity to retrieve the certificate and the Application Insights secret, with the permissions and cluster-side integration required by the selected charts configured separately. This module does not assign Key Vault permissions.
- An existing Key Vault certificate named `replace(https_endpoint, ".", "-")` and a secret containing the Application Insights connection string. Pass the secret's **name**, not its value.
- Existing Application Insights and any action groups supplied in `application_insights_action_group_ids`.
- When the TLS checker is enabled, schedulable nodes labelled `node_type=user`: the checker has a hard-coded required node affinity for this label.
- Network access from the Terraform runner to Azure, the Kubernetes API and the Helm repositories, and from the cluster to the configured container registries, Key Vault, Application Insights and the HTTPS endpoint. The TLS checker also uses an Azurite sidecar image from `mcr.microsoft.com`.
## Usage
The example uses existing Azure resources and a kubeconfig context. Replace the resource names, namespace, endpoint and context with your own values, and authenticate AzureRM using your environment's supported authentication method. The managed identity, its federation and Key Vault access must already be configured for `middleware-workload-identity` in namespace `middleware`.
The source path assumes this repository is available at `./.terraform/__v4__` in the calling project.
```hcl
variable "subscription_id" {
  type        = string
  description = "Azure subscription containing the monitoring resources."
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
provider "helm" {
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context = "aks-example"
  }
}
data "azurerm_key_vault" "middleware" {
  name                = "example-middleware-kv"
  resource_group_name = "example-security-rg"
}
data "azurerm_user_assigned_identity" "middleware" {
  name                = "example-middleware-identity"
  resource_group_name = "example-identity-rg"
}
data "azurerm_application_insights" "middleware" {
  name                = "example-middleware-ai"
  resource_group_name = "example-monitoring-rg"
}
data "azurerm_monitor_action_group" "operations" {
  name                = "example-operations"
  resource_group_name = "example-monitoring-rg"
}
module "kubernetes_middleware" {
  source = "./.terraform/__v4__/kubernetes_middleware"
  namespace       = "middleware"
  https_endpoint  = "api.example.com"
  location_string = "italynorth"
  keyvault_name                                            = data.azurerm_key_vault.middleware.name
  keyvault_tenant_id                                       = data.azurerm_key_vault.middleware.tenant_id
  kv_secret_name_for_application_insights_connection_string = "middleware-appinsights-connection-string"
  application_insights_resource_group   = data.azurerm_application_insights.middleware.resource_group_name
  application_insights_id               = data.azurerm_application_insights.middleware.id
  application_insights_action_group_ids = [data.azurerm_monitor_action_group.operations.id]
  # These inputs default to null but must be populated for this implementation.
  alert_name                             = "middleware-api-tls"
  workload_identity_service_account_name = "middleware-workload-identity"
  workload_identity_client_id            = data.azurerm_user_assigned_identity.middleware.client_id
  time_trigger             = "*/1 * * * *" # Optional
  expiration_delta_in_days = "7"           # Optional; this input is a string
}
```
For this example, the certificate must be named `api-example-com` in Key Vault. The secret `middleware-appinsights-connection-string` must refer to the Application Insights instance used by the alert.
## Examples
### Customize certificate mounter scheduling and resources
Add these optional arguments **inside the module block above**, rather than creating another instance in the same namespace. `tolerations` and `affinity` accept strings, not Terraform collections; `jsonencode` produces single-line JSON that can be embedded safely in the YAML template.
```hcl
  pod_ram = 64 # Optional; Mi, used for both request and limit
  pod_cpu = 20 # Optional; millicores, used for both request and limit
  tolerations = jsonencode([ # Optional
    {
      key      = "dedicated"
      operator = "Equal"
      value    = "middleware"
      effect   = "NoSchedule"
    }
  ])
  affinity = jsonencode({ # Optional
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [{
          matchExpressions = [{
            key      = "node_type"
            operator = "In"
            values   = ["user"]
          }]
        }]
      }
    }
  })
```
These settings apply only to the certificate mounter. They do not change the TLS checker's resources or scheduling, so do not rely on these tolerations to schedule the checker on tainted nodes.
### Disable alert evaluation
Set `alert_enabled = false` (optional) in the module block to retain the metric alert resource but disable evaluation. Supply `application_insights_action_group_ids = []` if no notification actions are wanted; this list is a required input even when empty. Neither setting disables the Helm releases.
## Inputs and outputs
There are no variable validation blocks. In addition to the declared types and defaults, observe the operational constraints in the notes below.
### Required inputs
These inputs have no default:
| Input | Type | Purpose |
| --- | --- | --- |
| `https_endpoint` | `string` | Hostname to check, without `https://`, a path or a port; also determines the certificate name and alert dimension. |
| `location_string` | `string` | Region string passed to the TLS checker; does not select an Azure deployment location. |
| `namespace` | `string` | Existing namespace for all three Helm releases. |
| `keyvault_name` | `string` | Existing Key Vault name, shared by both application charts. |
| `keyvault_tenant_id` | `string` | Tenant ID of the Key Vault. |
| `kv_secret_name_for_application_insights_connection_string` | `string` | Key Vault secret name passed through the checker's `envSecret.APPINSIGHTS_INSTRUMENTATIONKEY`. |
| `application_insights_resource_group` | `string` | Resource group in which to create the metric alert. |
| `application_insights_id` | `string` | Application Insights resource ID used as the alert scope. |
| `application_insights_action_group_ids` | `list(string)` | Action group resource IDs; may be `[]` for no actions. |
### Inputs with defaults
| Input | Type | Default | Purpose / constraint |
| --- | --- | --- | --- |
| `alert_name` | `string` | `null` | **Supply a non-null name**: also used to hash and construct the TLS checker release name. |
| `workload_identity_service_account_name` | `string` | `null` | **Supply a non-null service account name**: interpolated into both chart templates. |
| `workload_identity_client_id` | `string` | `null` | **Supply a non-null managed identity client ID**: interpolated into both chart templates. |
| `helm_chart_present` | `bool` | `true` | Controls creation of the TLS checker release only. |
| `helm_chart_version` | `string` | `"7.6.0"` | TLS checker's `microservice-chart` version. |
| `helm_chart_image_name` | `string` | `"ghcr.io/pagopa/infra-ssl-check"` | TLS checker image repository. |
| `helm_chart_image_tag` | `string` | `"v1.3.4@sha256:c3d45736706c981493b6216451fc65e99a69d5d64409ccb1c4ca93fef57c921d"` | TLS checker image tag and digest. |
| `time_trigger` | `string` | `"*/1 * * * *"` | Cron trigger passed unchanged to the checker. |
| `expiration_delta_in_days` | `string` | `"7"` | Certificate expiration threshold passed unchanged to the checker. |
| `alert_enabled` | `bool` | `true` | Enables metric alert evaluation; does not control resource creation. |
| `cert_mounter_chart_version` | `string` | `"2.0.2"` | Certificate mounter chart version. |
| `helm_release_name` | `string` | `"cert-mounter-blueprint"` | Certificate mounter release name; truncated to 53 characters, then dots are replaced by hyphens. |
| `pod_ram` | `number` | `30` | Certificate mounter memory request and limit in Mi. |
| `pod_cpu` | `number` | `10` | Certificate mounter CPU request and limit in millicores. |
| `tolerations` | `string` | `""` | Certificate mounter tolerations embedded in YAML; use `jsonencode` for structured values. |
| `affinity` | `string` | `""` | Certificate mounter affinity embedded in YAML; use `jsonencode` for structured values. |
**Outputs:** none. The module does not return certificate contents, Kubernetes secret names, Helm release details or alert IDs.
## Notes
- **Endpoint format:** the checker template prepends `https://` to `https_endpoint`, while the certificate mounter replaces only dots with hyphens to derive the Key Vault certificate name. Supply a hostname such as `api.example.com`, not a full URL.
- **Non-null inputs:** although `alert_name` defaults to `null` and the metric alert name has an endpoint fallback, the Helm release naming logic directly uses `sha256(var.alert_name)` and string interpolation. Set `alert_name` explicitly. The two Workload Identity inputs also default to `null`, but are interpolated directly into the templates and must be populated. There is no `workload_identity_enabled` input or alternative authentication switch.
- **Resource switches:** `helm_chart_present = false` omits only the TLS checker. The certificate mounter, Reloader and metric alert remain managed. The alert declares a dependency on the checker release and still targets the same availability metric; disabling the checker does not provide another source of telemetry.
- **Alert behavior:** the metric is `availabilityResults/availabilityPercentage`, aggregated as `Average`, with threshold `LessThan 50` and dimension `availabilityResult/name = https_endpoint`. Severity is `0`, frequency is `PT5M`, and `auto_mitigate` is `false`. These settings are not exposed as inputs. The module creates a metric alert, not an Application Insights web test.
- **Names and ownership:** the checker release name is built from a sanitized, lower-case `chckr-<alert_name>` prefix (up to 47 characters) plus the first five characters of the original alert name's SHA-256 hash. Reloader always uses the release name `reloader` in the supplied namespace. Avoid multiple instances in the same namespace or conflicts with existing releases, including separately managed TLS checker/certificate mounter installations. There is no switch to skip Reloader or the certificate mounter. Changing release names can require Helm uninstall/reinstall.
- **Scope of customization:** TLS checker requests and limits are fixed at `128Mi` memory and `70m` CPU, with separate Azurite sidecar limits of `100Mi` and `20m`. Its service and ingress creation are disabled in the values template. Reloader requests are `128Mi`/`10m` and limits are `256Mi`/`100m`. Only the certificate mounter uses `pod_ram`, `pod_cpu`, `tolerations` and `affinity`.
- **Chart behavior:** this module supplies chart values; certificate synchronization and reload behavior depend on those charts and the consuming workloads. It does not configure application ingresses or guarantee that every workload reloads a changed certificate.
## Troubleshooting
| Symptom | Checks |
| --- | --- |
| Null argument or template interpolation error | Set `alert_name`, `workload_identity_service_account_name` and `workload_identity_client_id` to non-null values. |
| Helm release name already in use | Check release ownership in the target namespace, especially the fixed `reloader` release and the default certificate mounter name. Do not deploy another instance to take over an existing release. |
| Helm cannot connect or namespace is missing | Check kubeconfig context, authentication, API connectivity, permissions and that the namespace exists. The module does not create it. |
| Pods remain pending | Check `node_type=user` nodes for the TLS checker, taints, available resources and any certificate mounter scheduling overrides. |
| Certificate or telemetry secret cannot be loaded | Check the exact Key Vault object names, tenant, workload identity client ID, federated subject, Key Vault permissions and network access. Verify the chart's Key Vault integration is configured. |
| No availability telemetry or notifications | Check the checker logs, endpoint reachability, the secret expected by the selected image through `APPINSIGHTS_INSTRUMENTATIONKEY`, and that telemetry reaches the Application Insights resource used by the alert. Check `helm_chart_present`, `alert_enabled`, the endpoint dimension and action group IDs. |
| YAML errors after scheduling overrides | Supply `tolerations` and `affinity` as encoded strings, as in the example, rather than raw Terraform lists/maps or incorrectly indented multiline YAML. |
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