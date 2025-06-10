# storage account

Module that allows the creation of a Storage account.
It creates a resource group named `azrmtest<6 hexnumbers>-rg` and every resource into it is named `azrmtest<6 hexnumbers>-*`.
In terraform output you can get the resource group name.

## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource` available for this module


## How to use it



<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account) | ../../storage_account | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action"></a> [action](#input\_action) | The ID of the Action Group and optional map of custom string properties to include with the post webhook operation. | <pre>set(object(<br/>    {<br/>      action_group_id    = string<br/>      webhook_properties = map(string)<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_custom_domain"></a> [custom\_domain](#input\_custom\_domain) | Custom domain for accessing blob data | <pre>object({<br/>    name          = string<br/>    use_subdomain = bool<br/>  })</pre> | <pre>{<br/>  "name": null,<br/>  "use_subdomain": false<br/>}</pre> | no |
| <a name="input_domain"></a> [domain](#input\_domain) | (Optional) Specifies the domain of the Storage Account. | `string` | `null` | no |
| <a name="input_enable_identity"></a> [enable\_identity](#input\_enable\_identity) | (Optional) If true, set the identity as SystemAssigned | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_error_404_document"></a> [error\_404\_document](#input\_error\_404\_document) | The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file. | `string` | `null` | no |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name od IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_immutability_policy"></a> [immutability\_policy](#input\_immutability\_policy) | Properties to setup the immutability policy. The resource can be created only with "Disabled" and "Unlocked" state. Change to "Locked" state doens't update the resource for a bug of the current module. | <pre>object({<br/>    enabled                       = bool<br/>    allow_protected_append_writes = optional(bool, false)<br/>    period_since_creation_in_days = optional(number, 730)<br/>  })</pre> | <pre>{<br/>  "allow_protected_append_writes": false,<br/>  "enabled": false,<br/>  "period_since_creation_in_days": 730<br/>}</pre> | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) region where the storage account will be created | `string` | n/a | yes |
| <a name="input_low_availability_threshold"></a> [low\_availability\_threshold](#input\_low\_availability\_threshold) | The Low Availability threshold. If metric average is under this value, the alert will be triggered. Default is 99.8 | `number` | `99.8` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) storage account name. Dashes and underscore will be removed. Max 24 chars | `string` | n/a | yes |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | n/a | <pre>object({<br/>    default_action             = string       # Specifies the default action of allow or deny when no other rules match. Valid options are Deny or Allow<br/>    bypass                     = set(string)  # Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None<br/>    ip_rules                   = list(string) # List of public IP or IP ranges in CIDR Format. Only IPV4 addresses are allowed<br/>    virtual_network_subnet_ids = list(string) # A list of resource ids for subnets.<br/>  })</pre> | `null` | no |
| <a name="input_private_dns_zone_blob_ids"></a> [private\_dns\_zone\_blob\_ids](#input\_private\_dns\_zone\_blob\_ids) | Used only for private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_dfs_ids"></a> [private\_dns\_zone\_dfs\_ids](#input\_private\_dns\_zone\_dfs\_ids) | Used only for private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_file_ids"></a> [private\_dns\_zone\_file\_ids](#input\_private\_dns\_zone\_file\_ids) | Used only for private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_queue_ids"></a> [private\_dns\_zone\_queue\_ids](#input\_private\_dns\_zone\_queue\_ids) | Used only for private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_table_ids"></a> [private\_dns\_zone\_table\_ids](#input\_private\_dns\_zone\_table\_ids) | Used only for private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_web_ids"></a> [private\_dns\_zone\_web\_ids](#input\_private\_dns\_zone\_web\_ids) | Used only for private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | Used only for private endpoints | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) product\_name used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | (Optional) storage account replication type. Default is the minimum replication type for the environment. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) Resource group name where to save the storage account | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_identity"></a> [identity](#output\_identity) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | n/a |
| <a name="output_primary_blob_connection_string"></a> [primary\_blob\_connection\_string](#output\_primary\_blob\_connection\_string) | n/a |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | n/a |
| <a name="output_primary_blob_host"></a> [primary\_blob\_host](#output\_primary\_blob\_host) | n/a |
| <a name="output_primary_connection_string"></a> [primary\_connection\_string](#output\_primary\_connection\_string) | n/a |
| <a name="output_primary_web_host"></a> [primary\_web\_host](#output\_primary\_web\_host) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->
