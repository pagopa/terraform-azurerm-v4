# Subnet

This module allow the creation of subnet

## IDH resources available
[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module



## How to use it

```hcl
module "postgres_flexible_snet" {
  source                                        = "./.terraform/modules/__v4__/IDH/subnet"
  name                                          = "${local.product}-test-idh-snet"
  resource_group_name                           = data.azurerm_resource_group.rg_vnet.name
  virtual_network_name                          = data.azurerm_virtual_network.vnet.name
  service_endpoints                             = ["Microsoft.Storage"]

  idh_resource_tier = "postgres_flexible"
  product_name = var.product_name
  env = var.env

}
```

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
| <a name="module_custom_nsg"></a> [custom\_nsg](#module\_custom\_nsg) | ../../network_security_group | n/a |
| <a name="module_embedded_nsg"></a> [embedded\_nsg](#module\_embedded\_nsg) | ../../network_security_group | n/a |
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_subnet"></a> [subnet](#module\_subnet) | ../../subnet | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.nsg_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [terraform_data.subnet_cidr](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.subnet_first_ip](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.subnet_last_ip](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |
| [external_external.subnet_cidr](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_self_inbound_nsg_rule"></a> [create\_self\_inbound\_nsg\_rule](#input\_create\_self\_inbound\_nsg\_rule) | (Optional) Flag the automatic creation of self-inbound security rules. Set to true to allow internal traffic within the same security scope | `bool` | `true` | no |
| <a name="input_custom_nsg_configuration"></a> [custom\_nsg\_configuration](#input\_custom\_nsg\_configuration) | (Optional) Custom NSG configuration, additional to eventually present embedded nsg | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string # short name for source_address_prefixes<br/>    target_ports                 = optional(list(string), null)<br/>    protocol                     = optional(string, null)<br/>    target_service               = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) List of allowed cidr and name. Available only if the subnet tier supports embedded nsg Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string # short name for source_address_prefixes<br/><br/>  })</pre> | <pre>{<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All"<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name od IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name of the subnet to be created | `string` | n/a | yes |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_private_endpoint_network_policies"></a> [private\_endpoint\_network\_policies](#input\_private\_endpoint\_network\_policies) | (Optional) Enable or Disable network policies for the private endpoint on the subnet. Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled. Defaults to Disabled. | `string` | `"Disabled"` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | n/a | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the Resource Group where the subnet should exist. | `string` | n/a | yes |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | (Optional) The list of Service endpoints to associate with the subnet. Possible values include: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB, Microsoft.ContainerRegistry, Microsoft.EventHub, Microsoft.KeyVault, Microsoft.ServiceBus, Microsoft.Sql, Microsoft.Storage and Microsoft.Web. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags added to the resources created by this module | `map(any)` | n/a | yes |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | (Required) Name of the virtual network where the subnet will be created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_prefixes"></a> [address\_prefixes](#output\_address\_prefixes) | n/a |
| <a name="output_first_ip_address"></a> [first\_ip\_address](#output\_first\_ip\_address) | First usable ip address in the subnet |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_last_ip_address"></a> [last\_ip\_address](#output\_last\_ip\_address) | Last usable ip address in the subnet |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_nsg_details"></a> [nsg\_details](#output\_nsg\_details) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | n/a |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | n/a |
| <a name="output_virtual_network_name"></a> [virtual\_network\_name](#output\_virtual\_network\_name) | n/a |
<!-- END_TF_DOCS -->
