# kubernetes_argocd_setup

Purpose: installs and configures Argo CD on AKS via Helm with Azure Entra ID (OIDC) and Azure Workload Identity.

Notes

- Change `argocd_force_reinstall_version` to force Helm reinstallation when needed.
- Admin password: provide `admin_password` or a secure one is generated and stored.
- Fine‑tune feature flags via the `enable_*` variables to skip parts you manage elsewhere.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.12 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd_workload_identity_configuration"></a> [argocd\_workload\_identity\_configuration](#module\_argocd\_workload\_identity\_configuration) | ../kubernetes_workload_identity_configuration | n/a |
| <a name="module_argocd_workload_identity_init"></a> [argocd\_workload\_identity\_init](#module\_argocd\_workload\_identity\_init) | ../kubernetes_workload_identity_init | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.argocd_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.argocd_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_private_dns_a_record.argocd_ingress](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.argocd_change_admin_password](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.restart_argocd_server](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.argocd_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Admin password (plain). If null, a random one is generated. | `string` | `null` | no |
| <a name="input_aks_name"></a> [aks\_name](#input\_aks\_name) | AKS cluster name | `string` | n/a | yes |
| <a name="input_aks_resource_group_name"></a> [aks\_resource\_group\_name](#input\_aks\_resource\_group\_name) | AKS resource group name | `string` | n/a | yes |
| <a name="input_argocd_application_namespaces"></a> [argocd\_application\_namespaces](#input\_argocd\_application\_namespaces) | Namespaces where ArgoCD can create applications | `list(string)` | n/a | yes |
| <a name="input_argocd_force_reinstall_version"></a> [argocd\_force\_reinstall\_version](#input\_argocd\_force\_reinstall\_version) | Change this value to force the reinstallation of ArgoCD | `string` | `""` | no |
| <a name="input_argocd_helm_release_version"></a> [argocd\_helm\_release\_version](#input\_argocd\_helm\_release\_version) | ArgoCD helm chart release version | `string` | `"8.3.7"` | no |
| <a name="input_argocd_internal_url"></a> [argocd\_internal\_url](#input\_argocd\_internal\_url) | Internal DNS hostname for ArgoCD | `string` | n/a | yes |
| <a name="input_dns_record_name_for_ingress"></a> [dns\_record\_name\_for\_ingress](#input\_dns\_record\_name\_for\_ingress) | DNS A record name for the ArgoCD ingress | `string` | `"argocd"` | no |
| <a name="input_enable_change_admin_password"></a> [enable\_change\_admin\_password](#input\_enable\_change\_admin\_password) | Enable patching of ArgoCD admin password | `bool` | `true` | no |
| <a name="input_enable_helm_release"></a> [enable\_helm\_release](#input\_enable\_helm\_release) | Enable ArgoCD helm release | `bool` | `true` | no |
| <a name="input_enable_private_dns_a_record"></a> [enable\_private\_dns\_a\_record](#input\_enable\_private\_dns\_a\_record) | Enable creation of Private DNS A record for ArgoCD | `bool` | `true` | no |
| <a name="input_enable_restart_argocd_server"></a> [enable\_restart\_argocd\_server](#input\_enable\_restart\_argocd\_server) | Enable restart of ArgoCD server deployment | `bool` | `true` | no |
| <a name="input_enable_store_admin_password"></a> [enable\_store\_admin\_password](#input\_enable\_store\_admin\_password) | Enable storing of ArgoCD admin password in Key Vault | `bool` | `true` | no |
| <a name="input_enable_store_admin_username"></a> [enable\_store\_admin\_username](#input\_enable\_store\_admin\_username) | Enable storing of ArgoCD admin username in Key Vault | `bool` | `true` | no |
| <a name="input_enable_workload_identity_configuration"></a> [enable\_workload\_identity\_configuration](#input\_enable\_workload\_identity\_configuration) | Enable workload identity configuration module | `bool` | `true` | no |
| <a name="input_enable_workload_identity_init"></a> [enable\_workload\_identity\_init](#input\_enable\_workload\_identity\_init) | Enable workload identity init module | `bool` | `true` | no |
| <a name="input_entra_admin_group_object_ids"></a> [entra\_admin\_group\_object\_ids](#input\_entra\_admin\_group\_object\_ids) | Azure Entra ID admin group object IDs | `list(string)` | `[]` | no |
| <a name="input_entra_app_client_id"></a> [entra\_app\_client\_id](#input\_entra\_app\_client\_id) | Workload identity application client id | `string` | n/a | yes |
| <a name="input_entra_developer_group_object_ids"></a> [entra\_developer\_group\_object\_ids](#input\_entra\_developer\_group\_object\_ids) | Azure Entra ID developer group object IDs | `list(string)` | `[]` | no |
| <a name="input_entra_guest_group_object_ids"></a> [entra\_guest\_group\_object\_ids](#input\_entra\_guest\_group\_object\_ids) | Azure Entra ID guest group object IDs | `list(string)` | `[]` | no |
| <a name="input_entra_reader_group_object_ids"></a> [entra\_reader\_group\_object\_ids](#input\_entra\_reader\_group\_object\_ids) | Azure Entra ID reader group object IDs | `list(string)` | `[]` | no |
| <a name="input_ingress_load_balancer_ip"></a> [ingress\_load\_balancer\_ip](#input\_ingress\_load\_balancer\_ip) | Ingress Controller Load Balancer IP | `string` | n/a | yes |
| <a name="input_ingress_tls_secret_name"></a> [ingress\_tls\_secret\_name](#input\_ingress\_tls\_secret\_name) | TLS secret name for ArgoCD ingress | `string` | `null` | no |
| <a name="input_internal_dns_zone_name"></a> [internal\_dns\_zone\_name](#input\_internal\_dns\_zone\_name) | Internal Private DNS Zone name | `string` | n/a | yes |
| <a name="input_internal_dns_zone_resource_group_name"></a> [internal\_dns\_zone\_resource\_group\_name](#input\_internal\_dns\_zone\_resource\_group\_name) | Resource group name for internal Private DNS Zone | `string` | n/a | yes |
| <a name="input_kv_id"></a> [kv\_id](#input\_kv\_id) | Key Vault id | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure location | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace where ArgoCD is installed | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Azure tenant id | `string` | n/a | yes |
| <a name="input_workload_identity_resource_group_name"></a> [workload\_identity\_resource\_group\_name](#input\_workload\_identity\_resource\_group\_name) | Resource group for workload identity resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_workload_identity_client_id"></a> [workload\_identity\_client\_id](#output\_workload\_identity\_client\_id) | Client ID created by workload identity configuration |
| <a name="output_workload_identity_service_account_name"></a> [workload\_identity\_service\_account\_name](#output\_workload\_identity\_service\_account\_name) | Service Account name created by workload identity configuration |
<!-- END_TF_DOCS -->
