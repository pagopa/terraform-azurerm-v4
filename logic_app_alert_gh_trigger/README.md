## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.30.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_federated_identity_credential.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_logic_app_action_custom.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom) | resource |
| [azurerm_logic_app_action_http.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_http) | resource |
| [azurerm_logic_app_trigger_http_request.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_trigger_http_request) | resource |
| [azurerm_logic_app_workflow.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_workflow) | resource |
| [azurerm_role_assignment.user_aid](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subscription.primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_identity"></a> [create\_identity](#input\_create\_identity) | (Optional) Whether to create a User-assigned managed identity for the Logic App Workflow. | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) The environment where the Logic App Workflow should be deployed. | `string` | n/a | yes |
| <a name="input_event_type"></a> [event\_type](#input\_event\_type) | (Required) The type of event to dispatch to GitHub repository. | `string` | `"azure-alert"` | no |
| <a name="input_github"></a> [github](#input\_github) | (Required) GitHub organization and repository configuration for the workflow trigger. | <pre>object({<br/>    org        = string<br/>    repository = string<br/>    pat        = string<br/>  })</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | (Required) The location where the Logic App Workflow should be created. | `string` | `"westeurope"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the Logic App Workflow. | `string` | `"test"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group in which to create the Logic App Workflow. | `string` | `"test-rg-devopslab-ffppa"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the Logic App Workflow. | `map(string)` | `{}` | no |
| <a name="input_workflow"></a> [workflow](#input\_workflow) | (Optional) Specify the workflow input parameters and schema version to use. | <pre>object({<br/>    workflow_parameters = optional(map(string), {})<br/>    workflow_schema     = optional(string)<br/>    workflow_version    = optional(string)<br/>  })</pre> | <pre>{<br/>  "workflow_parameters": {},<br/>  "workflow_schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",<br/>  "workflow_version": "1.0.0.0"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_location"></a> [location](#output\_location) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_trigger_callback_url"></a> [trigger\_callback\_url](#output\_trigger\_callback\_url) | n/a |
| <a name="output_workflow_parameters"></a> [workflow\_parameters](#output\_workflow\_parameters) | n/a |
