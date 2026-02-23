# keycloak_entra

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_app_role_assignment.keycloak_groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.keycloak](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.client_secret](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.keycloak_sp](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_delegated_permission_grant.consent](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_delegated_permission_grant) | resource |
| [azuread_group.ad_owners](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_group.groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_service_principal.graph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_owners"></a> [ad\_owners](#input\_ad\_owners) | List of Azure Active Directory group display names that will be assigned as owners of the Keycloak Enterprise Application and App Registration | `list(string)` | `[]` | no |
| <a name="input_authorized_group_names"></a> [authorized\_group\_names](#input\_authorized\_group\_names) | List of AD group display names authorized to access the application and whose IDs will be mapped in Keycloak. | `list(string)` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | n/a | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_logout_url"></a> [logout\_url](#input\_logout\_url) | The URL where Microsoft Entra ID will send a request when the user signs out | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_redirect_uris"></a> [redirect\_uris](#input\_redirect\_uris) | A list of authorized redirect URIs (Reply URLs) where Entra ID will send the authentication responses. These should point to the Keycloak broker endpoints | `list(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
