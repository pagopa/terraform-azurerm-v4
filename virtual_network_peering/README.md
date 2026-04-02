# Virtual Network Peering

## Description

This module provisions bidirectional virtual network peering between two Azure virtual networks, enabling communication between resources across peered networks with configurable access controls.

## Usage

```hcl
module "vnet_peering_core_2_aks" {
  source = "./"

  # Required variables
  source_resource_group_name       = data.azurerm_resource_group.rg_vnet.name
  source_virtual_network_name      = data.azurerm_virtual_network.vnet.name
  source_remote_virtual_network_id = data.azurerm_virtual_network.vnet.id

  target_resource_group_name       = azurerm_resource_group.rg_vnet_aks.name
  target_virtual_network_name      = module.vnet_aks.name
  target_remote_virtual_network_id = module.vnet_aks.id

  # Optional variables
  source_allow_gateway_transit = false # needed by vpn gateway for enabling routing from vnet to vnet_integration
  target_use_remote_gateways   = false # needed by vpn gateway for enabling routing from vnet to vnet_integration
}
```

## Examples

### Basic bidirectional peering

```hcl
module "vnet_peering" {
  source = "./"

  source_resource_group_name       = azurerm_resource_group.source.name
  source_virtual_network_name      = azurerm_virtual_network.source.name
  source_remote_virtual_network_id = azurerm_virtual_network.target.id

  target_resource_group_name       = azurerm_resource_group.target.name
  target_virtual_network_name      = azurerm_virtual_network.target.name
  target_remote_virtual_network_id = azurerm_virtual_network.source.id
}
```

### Peering with custom names and gateway transit

```hcl
module "vnet_peering_with_gateway" {
  source = "./"

  source_resource_group_name       = azurerm_resource_group.hub.name
  source_virtual_network_name      = azurerm_virtual_network.hub.name
  source_remote_virtual_network_id = azurerm_virtual_network.spoke.id
  source_allow_gateway_transit     = true

  target_resource_group_name       = azurerm_resource_group.spoke.name
  target_virtual_network_name      = azurerm_virtual_network.spoke.name
  target_remote_virtual_network_id = azurerm_virtual_network.hub.id
  target_use_remote_gateways       = true

  source_custom_name = "hub-to-spoke-peering"
  target_custom_name = "spoke-to-hub-peering"
}
```

## Notes

- This module creates **bidirectional** peering between two virtual networks. Each direction is controlled separately with `source_*` and `target_*` variables.
- Default peering names are automatically generated as `{source_vnet_name}-to-{target_vnet_name}` and `{target_vnet_name}-to-{source_vnet_name}` unless custom names are provided.
- By default, virtual network access is enabled (`true`) for both directions, but forwarded traffic and gateway transit are disabled (`false`).
- When using gateway transit patterns (hub-and-spoke topology), enable `source_allow_gateway_transit` on the hub and `target_use_remote_gateways` on the spoke.

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
| [azurerm_virtual_network_peering.source](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.target](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_source_allow_forwarded_traffic"></a> [source\_allow\_forwarded\_traffic](#input\_source\_allow\_forwarded\_traffic) | Controls if forwarded traffic from VMs in the remote virtual network is allowed. | `bool` | `false` | no |
| <a name="input_source_allow_gateway_transit"></a> [source\_allow\_gateway\_transit](#input\_source\_allow\_gateway\_transit) | Controls gatewayLinks can be used in the remote virtual network’s link to the local virtual network. | `bool` | `false` | no |
| <a name="input_source_allow_virtual_network_access"></a> [source\_allow\_virtual\_network\_access](#input\_source\_allow\_virtual\_network\_access) | Controls if the VMs in the remote virtual network can access VMs in the local virtual network. | `bool` | `true` | no |
| <a name="input_source_custom_name"></a> [source\_custom\_name](#input\_source\_custom\_name) | (Optional) source peering custom name. if not defined a default calculated name will be used | `string` | `null` | no |
| <a name="input_source_remote_virtual_network_id"></a> [source\_remote\_virtual\_network\_id](#input\_source\_remote\_virtual\_network\_id) | The full Azure resource ID of the remote virtual network from which the peering starts. | `string` | n/a | yes |
| <a name="input_source_resource_group_name"></a> [source\_resource\_group\_name](#input\_source\_resource\_group\_name) | The name of the resource group in which to start the virtual network peering | `string` | n/a | yes |
| <a name="input_source_use_remote_gateways"></a> [source\_use\_remote\_gateways](#input\_source\_use\_remote\_gateways) | Controls if remote gateways can be used on the local virtual network | `bool` | `false` | no |
| <a name="input_source_virtual_network_name"></a> [source\_virtual\_network\_name](#input\_source\_virtual\_network\_name) | The name of the virtual network from which the peering starts | `string` | n/a | yes |
| <a name="input_target_allow_forwarded_traffic"></a> [target\_allow\_forwarded\_traffic](#input\_target\_allow\_forwarded\_traffic) | Controls if forwarded traffic from VMs in the remote virtual network is allowed. | `bool` | `false` | no |
| <a name="input_target_allow_gateway_transit"></a> [target\_allow\_gateway\_transit](#input\_target\_allow\_gateway\_transit) | Controls gatewayLinks can be used in the remote virtual network’s link to the local virtual network. | `bool` | `false` | no |
| <a name="input_target_allow_virtual_network_access"></a> [target\_allow\_virtual\_network\_access](#input\_target\_allow\_virtual\_network\_access) | Controls if the VMs in the remote virtual network can access VMs in the local virtual network. | `bool` | `true` | no |
| <a name="input_target_custom_name"></a> [target\_custom\_name](#input\_target\_custom\_name) | (Optional) target peering custom name. if not defined a default calculated name will be used | `string` | `null` | no |
| <a name="input_target_remote_virtual_network_id"></a> [target\_remote\_virtual\_network\_id](#input\_target\_remote\_virtual\_network\_id) | The full Azure resource ID of the remote virtual network from which the peering ends. | `string` | n/a | yes |
| <a name="input_target_resource_group_name"></a> [target\_resource\_group\_name](#input\_target\_resource\_group\_name) | The name of the resource group in which to end the virtual network peering | `string` | `null` | no |
| <a name="input_target_use_remote_gateways"></a> [target\_use\_remote\_gateways](#input\_target\_use\_remote\_gateways) | Controls if remote gateways can be used on the local virtual network | `bool` | `false` | no |
| <a name="input_target_virtual_network_name"></a> [target\_virtual\_network\_name](#input\_target\_virtual\_network\_name) | The name of the virtual network from which the peering ends | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_source_id"></a> [source\_id](#output\_source\_id) | The ID of the source virtual network peering resource |
| <a name="output_source_name"></a> [source\_name](#output\_source\_name) | The name of the source virtual network peering |
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | The ID of the target virtual network peering resource |
| <a name="output_target_name"></a> [target\_name](#output\_target\_name) | The name of the target virtual network peering |
<!-- END_TF_DOCS -->
