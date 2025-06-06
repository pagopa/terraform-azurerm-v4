# Redis cache

This module allows the creation of a redis cache

Availability Zone are choosed automatically by Azure. If you want to override the default zones choosed automatically, you can use the `custom_zones` variable.
# https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-whats-new#cache-creation-with-zone-redundancy-by-default

# Migration v3 -> v4

* `zones`: was changed to `custom_zones` is Optional and now is valid only for premium and only if you want to override the default zones choosed automatically

## How to use

See test folder for examples

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ../../redis_cache | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_metric_alert.redis_cache_used_memory_exceeded](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_action_group_ids"></a> [alert\_action\_group\_ids](#input\_alert\_action\_group\_ids) | (Optional) List of action group ids to be used in alerts | `list(string)` | `[]` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_idh_resource"></a> [idh\_resource](#input\_idh\_resource) | (Required) The name od IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location of the resource group. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the Redis instance. | `string` | n/a | yes |
| <a name="input_patch_schedules"></a> [patch\_schedules](#input\_patch\_schedules) | (Optional) List of day-time where Azure can start the maintenance activity | <pre>list(object({<br/>    day_of_week    = string<br/>    start_hour_utc = number<br/>  }))</pre> | `null` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | (Optional) Enable private endpoint with required params | <pre>object({<br/>    subnet_id            = string<br/>    private_dns_zone_ids = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_private_static_ip_address"></a> [private\_static\_ip\_address](#input\_private\_static\_ip\_address) | The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) product\_name used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The Subnet within which the Redis Cache should be deployed (Deprecated, use private\_endpoint) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hostname"></a> [hostname](#output\_hostname) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_location"></a> [location](#output\_location) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_port"></a> [port](#output\_port) | n/a |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | Access Keys |
| <a name="output_primary_connection_string"></a> [primary\_connection\_string](#output\_primary\_connection\_string) | n/a |
| <a name="output_primary_connection_url"></a> [primary\_connection\_url](#output\_primary\_connection\_url) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_secondary_access_key"></a> [secondary\_access\_key](#output\_secondary\_access\_key) | n/a |
| <a name="output_secondary_connection_string"></a> [secondary\_connection\_string](#output\_secondary\_connection\_string) | n/a |
| <a name="output_secondary_connection_url"></a> [secondary\_connection\_url](#output\_secondary\_connection\_url) | n/a |
| <a name="output_sku"></a> [sku](#output\_sku) | n/a |
| <a name="output_ssl_port"></a> [ssl\_port](#output\_ssl\_port) | n/a |
<!-- END_TF_DOCS -->
