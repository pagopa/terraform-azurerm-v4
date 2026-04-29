# Container app environment

This resource allow the creation of a Container App Environment as Consumption plan (Workload profiles are not supported by this module).

Deploying the Container app environment in a custom subnet, unlocks other features such as zone redundancy and internal load balancing.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app_environment.container_app_environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_internal_load_balancer"></a> [internal\_load\_balancer](#input\_internal\_load\_balancer) | Internal Load Balancing Mode. Can be true only if a subnet\_id is provided | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Resource location. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics Workspace resource id | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Resource name | `string` | n/a | yes |
| <a name="input_private_endpoint_config"></a> [private\_endpoint\_config](#input\_private\_endpoint\_config) | Configuration for private endpoint and DNS zones for Container Apps Environment | <pre>object({<br/>    enabled              = bool<br/>    subnet_id            = optional(string, null)<br/>    private_dns_zone_ids = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | (Optional) Subnet id if the environment is in a custom virtual network | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_workload_profiles"></a> [workload\_profiles](#input\_workload\_profiles) | Workload profiles list | <pre>list(object({<br/>    name      = string<br/>    type      = string<br/>    min_count = number<br/>    max_count = number<br/>  }))</pre> | `[]` | no |
| <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant) | Deploy multi zone environment. Can be true only if a subnet\_id is provided | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->
