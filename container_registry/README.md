# azure container registry

Module that allows the creation of azure container registry.

## Architecture

TBD

## Limits and constraints

- **Private endpoints** is avaible only for Premium sku.

## Migration form modules < v8

### deprecations
* `var.private_endpoint.enabled` was deprecated: use `var.private_endpoint_enabled`

### new variables
* `var.monitor_diagnostic_setting_enabled`: allow to enable monitor setting (deprecated) because we use the azure policy

### default values
All the changed enable the module to be production ready

* `sku`: now is "Premium"
* `zone_redundancy_enabled`: is true
* `public_network_access_enabled`: is false

## How to use it

See tests folder

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
| [azurerm_container_registry.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_enabled"></a> [admin\_enabled](#input\_admin\_enabled) | (Optional) Specifies whether the admin user is enabled. Defaults to false. | `bool` | `false` | no |
| <a name="input_anonymous_pull_enabled"></a> [anonymous\_pull\_enabled](#input\_anonymous\_pull\_enabled) | (Optional) Whether allows anonymous (unauthenticated) pull access to this Container Registry? Defaults to false. This is only supported on resources with the Standard or Premium SKU. | `bool` | `false` | no |
| <a name="input_georeplications"></a> [georeplications](#input\_georeplications) | A list of Azure locations where the container registry should be geo-replicated. | <pre>list(object({<br/>    location                  = string<br/>    regional_endpoint_enabled = bool<br/>    zone_redundancy_enabled   = bool<br/>  }))</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_monitor_diagnostic_setting_enabled"></a> [monitor\_diagnostic\_setting\_enabled](#input\_monitor\_diagnostic\_setting\_enabled) | Enable monitor diagnostic setting | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_network_rule_bypass_option"></a> [network\_rule\_bypass\_option](#input\_network\_rule\_bypass\_option) | (Optional) Whether to allow trusted Azure services to access a network restricted Container Registry? Possible values are None and AzureServices. Defaults to AzureServices. | `string` | `"AzureServices"` | no |
| <a name="input_network_rule_set"></a> [network\_rule\_set](#input\_network\_rule\_set) | A list of network rule set defined at https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry#network_rule_set | <pre>list(object({<br/>    default_action = string<br/>    ip_rule = list(object({<br/>      action   = string<br/>      ip_range = string<br/>    }))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "default_action": "Deny",<br/>    "ip_rule": []<br/>  }<br/>]</pre> | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | (Required) Enable and configure private endpoint with required params | <pre>object({<br/>    virtual_network_id   = string<br/>    subnet_id            = string<br/>    private_dns_zone_ids = list(string)<br/>  })</pre> | <pre>{<br/>  "private_dns_zone_ids": [<br/>    ""<br/>  ],<br/>  "subnet_id": null,<br/>  "virtual_network_id": null<br/>}</pre> | no |
| <a name="input_private_endpoint_enabled"></a> [private\_endpoint\_enabled](#input\_private\_endpoint\_enabled) | Enable private endpoint, default: true | `bool` | `true` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | (Optional) Whether public network access is allowed for the container registry. Defaults to true. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_sec_log_analytics_workspace_id"></a> [sec\_log\_analytics\_workspace\_id](#input\_sec\_log\_analytics\_workspace\_id) | Log analytics workspace security (it should be in a different subscription). | `string` | `null` | no |
| <a name="input_sec_storage_id"></a> [sec\_storage\_id](#input\_sec\_storage\_id) | Storage Account security (it should be in a different subscription). | `string` | `null` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | (Required) The SKU name of the container registry. Possible values are Basic, Standard and Premium. | `string` | `"Premium"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_zone_redundancy_enabled"></a> [zone\_redundancy\_enabled](#input\_zone\_redundancy\_enabled) | (Optional) Whether zone redundancy is enabled for this Container Registry? Changing this forces a new resource to be created. Defaults to false. | `string` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password"></a> [admin\_password](#output\_admin\_password) | n/a |
| <a name="output_admin_username"></a> [admin\_username](#output\_admin\_username) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_login_server"></a> [login\_server](#output\_login\_server) | n/a |
<!-- END_TF_DOCS -->
