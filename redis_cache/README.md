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

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_redis_cache.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_configuration"></a> [backup\_configuration](#input\_backup\_configuration) | n/a | <pre>object({<br/>    frequency                 = number<br/>    max_snapshot_count        = number<br/>    storage_connection_string = string<br/>  })</pre> | `null` | no |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | The size of the Redis cache to deploy | `number` | `1` | no |
| <a name="input_custom_zones"></a> [custom\_zones](#input\_custom\_zones) | (Optional/Premium Only) Specifies a list of Availability Zones in which this Redis Cache should be located. Changing this forces a new Redis Cache to be created. | `list(number)` | `[]` | no |
| <a name="input_data_persistence_authentication_method"></a> [data\_persistence\_authentication\_method](#input\_data\_persistence\_authentication\_method) | (Optional) Preferred auth method to communicate to storage account used for data persistence. Possible values are SAS and ManagedIdentity. Defaults to SAS. | `string` | `"SAS"` | no |
| <a name="input_enable_authentication"></a> [enable\_authentication](#input\_enable\_authentication) | If set to false, the Redis instance will be accessible without authentication. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_non_ssl_port"></a> [enable\_non\_ssl\_port](#input\_enable\_non\_ssl\_port) | Enable the non-SSL port (6379) - disabled by default. | `bool` | `false` | no |
| <a name="input_family"></a> [family](#input\_family) | The SKU family/pricing group to use | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location of the resource group. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the Redis instance. | `string` | n/a | yes |
| <a name="input_patch_schedules"></a> [patch\_schedules](#input\_patch\_schedules) | n/a | <pre>list(object({<br/>    day_of_week    = string<br/>    start_hour_utc = number<br/>  }))</pre> | `[]` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | (Required) Enable private endpoint with required params | <pre>object({<br/>    enabled              = bool<br/>    subnet_id            = string<br/>    private_dns_zone_ids = list(string)<br/>  })</pre> | n/a | yes |
| <a name="input_private_static_ip_address"></a> [private\_static\_ip\_address](#input\_private\_static\_ip\_address) | The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether or not public network access is allowed for this Redis Cache. true means this resource could be accessed by both public and private endpoint. false means only private endpoint access is allowed. Defaults to false. | `string` | `false` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | The version of Redis to use: 4 (deprecated) or 6 | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_shard_count"></a> [shard\_count](#input\_shard\_count) | The number of Shards to create on the Redis Cluster. | `number` | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU of Redis to use | `string` | n/a | yes |
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
