# EventHub

This module allows the creation of a event hub namespace, as well as the creation of a private endpoint for the event hub namespace.

## IDH resources available
[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module


## How to use

```hcl
module "evh" {
  source = "./.terraform/modules/__v4__/IDH/event_hub"

  env = var.env
  idh_resource_tier = "standard"
  location = var.location
  
  name = "myeventhub"
  prefix = var.prefix
  resource_group_name = azurerm_resource_group.evh_rg.name
  tags = var.tags

}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.36 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_event_hub"></a> [event\_hub](#module\_event\_hub) | ../../eventhub | n/a |
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_private_endpoint_snet"></a> [private\_endpoint\_snet](#module\_private\_endpoint\_snet) | ../subnet | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action"></a> [action](#input\_action) | The ID of the Action Group and optional map of custom string properties to include with the post webhook operation. | <pre>set(object(<br/>    {<br/>      action_group_id    = string<br/>      webhook_properties = map(string)<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) List of allowed cidr and name . Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string # short name for source_address_prefixes<br/>  })</pre> | <pre>{<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All"<br/>}</pre> | no |
| <a name="input_embedded_subnet"></a> [embedded\_subnet](#input\_embedded\_subnet) | (Optional) Configuration for creating an embedded Subnet for the Redis private endpoint. When enabled, 'private\_endpoint.subnet\_id' must be null. | <pre>object({<br/>    enabled      = bool<br/>    vnet_name    = optional(string, null)<br/>    vnet_rg_name = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_eventhubs"></a> [eventhubs](#input\_eventhubs) | A list of event hubs to add to namespace. | <pre>list(object({<br/>    name              = string       # (Required) Specifies the name of the EventHub resource. Changing this forces a new resource to be created.<br/>    partitions        = number       # (Required) Specifies the current number of shards on the Event Hub.<br/>    message_retention = number       # (Required) Specifies the number of days to retain the events for this Event Hub.<br/>    consumers         = list(string) # Manages a Event Hubs Consumer Group as a nested resource within an Event Hub.<br/>    keys = list(object({<br/>      name   = string # (Required) Specifies the name of the EventHub Authorization Rule resource. Changing this forces a new resource to be created.<br/>      listen = bool   # (Optional) Does this Authorization Rule have permissions to Listen to the Event Hub? Defaults to false.<br/>      send   = bool   # (Optional) Does this Authorization Rule have permissions to Send to the Event Hub? Defaults to false.<br/>      manage = bool   # (Optional) Does this Authorization Rule have permissions to Manage to the Event Hub? When this property is true - both listen and send must be too. Defaults to false.<br/>    }))               # Manages a Event Hubs authorization Rule within an Event Hub.<br/>  }))</pre> | `[]` | no |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name of IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_metric_alerts"></a> [metric\_alerts](#input\_metric\_alerts) | Map of name = criteria objects | <pre>map(object({<br/>    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]<br/>    aggregation = string<br/>    metric_name = string<br/>    description = string<br/>    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]<br/>    operator  = string<br/>    threshold = number<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H<br/>    frequency = string<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.<br/>    window_size = string<br/><br/>    dimension = list(object(<br/>      {<br/>        name     = string<br/>        operator = string<br/>        values   = list(string)<br/>      }<br/>    ))<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Eventhub namespace description. | `string` | n/a | yes |
| <a name="input_network_rulesets"></a> [network\_rulesets](#input\_network\_rulesets) | n/a | <pre>list(object({<br/>    default_action                = string                #  (Required) The default action to take when a rule is not matched. Possible values are Allow and Deny.<br/>    public_network_access_enabled = optional(bool, false) # (Optional) Is public network access enabled for the EventHub Namespace? Defaults to false.<br/>    virtual_network_rule = list(object({<br/>      subnet_id                                       = string # (Required) The id of the subnet to match on.<br/>      ignore_missing_virtual_network_service_endpoint = bool   # (Optional) Are missing virtual network service endpoints ignored?<br/>    }))<br/>    ip_rule = list(object({<br/>      ip_mask = string # (Required) The IP mask to match on.<br/>      action  = string # (Optional) The action to take when the rule is matched. Possible values are Allow. Defaults to Allow.<br/>    }))<br/>    trusted_service_access_enabled = optional(bool, false) #Whether Trusted Microsoft Services are allowed to bypass firewall.<br/>  }))</pre> | `[]` | no |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_private_dns_zones_ids"></a> [private\_dns\_zones\_ids](#input\_private\_dns\_zones\_ids) | Private DNS Zones where the private endpoint will be created | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_resource_group_name"></a> [private\_endpoint\_resource\_group\_name](#input\_private\_endpoint\_resource\_group\_name) | Name of the resource group where the private endpoint will be created | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | (Deprecated) The id of the subnet that will be used for the private endpoint. Use embedded\_subnet instead. | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) prefix used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | The name of this Event Hub |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | Id of Event Hub Namespace. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->
