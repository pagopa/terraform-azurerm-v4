# kubernetes_argocd_entra

Purpose: provisions the Azure Entra ID (Azure AD) integration needed by Argo CD.

Manual steps after apply

- Grant admin consent: in Azure Portal open the Enterprise Application, go to
  > API permissions > Microsoft Graph > User.Read and click “Grant admin consent”.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_app_role_assignment.argocd_group_assignments](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.argocd](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_federated_identity_credential.argocd](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_service_principal.sp_argocd](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_delegated_permission_grant.argocd_user_read_consent](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_delegated_permission_grant) | resource |
| [azurerm_key_vault_secret.argocd_entra_app_client_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.argocd_entra_app_service_account_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azuread_group.argocd_groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_service_principal.graph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_kubernetes_cluster.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_name"></a> [aks\_name](#input\_aks\_name) | AKS cluster name (to resolve OIDC issuer) | `string` | n/a | yes |
| <a name="input_aks_resource_group_name"></a> [aks\_resource\_group\_name](#input\_aks\_resource\_group\_name) | AKS cluster resource group name | `string` | n/a | yes |
| <a name="input_argocd_hostname"></a> [argocd\_hostname](#input\_argocd\_hostname) | FQDN used by ArgoCD (internal/external) | `string` | n/a | yes |
| <a name="input_argocd_namespace"></a> [argocd\_namespace](#input\_argocd\_namespace) | Kubernetes namespace of ArgoCD server | `string` | `"argocd"` | no |
| <a name="input_argocd_service_account_name"></a> [argocd\_service\_account\_name](#input\_argocd\_service\_account\_name) | ServiceAccount name used by ArgoCD server | `string` | `"argocd-server"` | no |
| <a name="input_entra_app_owners_object_ids"></a> [entra\_app\_owners\_object\_ids](#input\_entra\_app\_owners\_object\_ids) | Object IDs for Entra app owners | `list(string)` | n/a | yes |
| <a name="input_entra_group_display_names"></a> [entra\_group\_display\_names](#input\_entra\_group\_display\_names) | Entra group display names to assign to the Enterprise App | `list(string)` | `[]` | no |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Key Vault ID where to store outputs | `string` | n/a | yes |
| <a name="input_kv_secret_app_client_id_name"></a> [kv\_secret\_app\_client\_id\_name](#input\_kv\_secret\_app\_client\_id\_name) | Key Vault secret name for the ArgoCD Entra app client id | `string` | `"argocd-entra-app-workload-client-id"` | no |
| <a name="input_kv_secret_service_account_name"></a> [kv\_secret\_service\_account\_name](#input\_kv\_secret\_service\_account\_name) | Key Vault secret name for the ArgoCD service account name | `string` | `"argocd-entra-app-workload-service-account-name"` | no |
| <a name="input_name_identifier"></a> [name\_identifier](#input\_name\_identifier) | Project prefix (e.g., cstar) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | AzureAD application (client) ID |
| <a name="output_application_object_id"></a> [application\_object\_id](#output\_application\_object\_id) | AzureAD application object ID |
| <a name="output_service_principal_object_id"></a> [service\_principal\_object\_id](#output\_service\_principal\_object\_id) | Enterprise application (Service Principal) object ID |
<!-- END_TF_DOCS -->
