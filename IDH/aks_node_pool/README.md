# AKS Node Pool

This module creates one or two AKS node pools on an existing Azure Kubernetes Service cluster, using pre-approved VM sizes and disk configurations loaded from the IDH catalogue.

## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource_tiers` available for this module.

## How to use it

### Basic usage – single node pool with external subnet

```hcl
module "aks_node_pool" {
  source = "./.terraform/modules/__v4__/IDH/aks_node_pool"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = "Standard_D4ds"

  name                  = "mypool"
  kubernetes_cluster_id = data.azurerm_kubernetes_cluster.aks.id
  vnet_subnet_id        = data.azurerm_subnet.aks_snet.id

  node_count_min = 1
  node_count_max = 3

  node_labels = {
    "node-pool" = "mypool"
  }
  node_tags = var.tags
  tags      = var.tags
}
```

### With embedded subnet – node pool that creates its own overlay subnet

When `embedded_subnet.enabled = true`, the module provisions a dedicated overlay subnet and associates it with the provided NAT Gateway. In this case, `vnet_subnet_id` must be omitted (or left as `null`).

```hcl
module "aks_node_pool" {
  source = "./.terraform/modules/__v4__/IDH/aks_node_pool"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = "Standard_D4ds"

  name                  = "mypool"
  kubernetes_cluster_id = data.azurerm_kubernetes_cluster.aks.id

  node_count_min = 1
  node_count_max = 3

  embedded_subnet = {                                         # optional
    enabled      = true
    vnet_name    = data.azurerm_virtual_network.vnet.name
    vnet_rg_name = data.azurerm_virtual_network.vnet.resource_group_name
    subnet_name  = "mypool-overlay-snet"
    natgw_id     = data.azurerm_nat_gateway.natgw.id
  }

  node_labels = {
    "node-pool" = "mypool"
  }
  node_tags = var.tags
  tags      = var.tags
}
```

### Double node pool – foo-bar rotation

When `double_node_pool.enabled = true`, the module creates two node pools named `<name>foo` and `<name>bar`. Only the pool marked `active = true` will have a non-zero minimum node count; the other pool is kept at zero nodes so it does not consume quota. This pattern lets you rotate node pools (e.g. to apply a new VM image or SKU) without downtime by switching which pool is active in successive Terraform applies.

> **Note:** when `double_node_pool` is enabled the `name` value must be **≤ 9 characters**, because the suffixes `foo` / `bar` are appended to reach the 12-character AKS limit.

```hcl
module "aks_node_pool" {
  source = "./.terraform/modules/__v4__/IDH/aks_node_pool"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = "Standard_D4ds"

  name                  = "workers"  # ≤ 9 chars when double_node_pool is enabled
  kubernetes_cluster_id = data.azurerm_kubernetes_cluster.aks.id
  vnet_subnet_id        = data.azurerm_subnet.aks_snet.id

  node_count_min = 1
  node_count_max = 5

  double_node_pool = {                # optional
    enabled = true
    node_pool_foo = {
      active = true   # workersfoo is live; workersfoo will handle traffic
    }
    node_pool_bar = {
      active = false  # workersbar is standby (min = 0); rotate here on next cycle
      version_override = "1.34.2"  # optional override to use a different Kubernetes version than the cluster default
    }
  }

  node_labels = {
    "node-pool" = "workers"
  }
  node_tags = var.tags
  tags      = var.tags
}
```

**foo-bar rotation workflow:**

1. Activate the inactive node pool
2. Remove the autoscale from the old active node pool (from portal)
3. Drain the old active node pool and cordon it to prevent new pods from being scheduled
4. Deactivate the old active node pool

## Notes

- `vnet_subnet_id` and `embedded_subnet.enabled = true` are **mutually exclusive**. Setting both will cause a validation error.
- `os_disk_type` and `os_disk_size_gb` default to the values defined by the IDH tier. Override them only when you have a specific requirement.
- `node_count_min` must be greater than or equal to the minimum allowed by the selected IDH tier; a validation error is raised otherwise.
- `autoscale_enabled` defaults to `true`. The cluster autoscaler will scale between `node_count_min` and `node_count_max`.
- The `id` and `name` outputs are deprecated. Prefer `node_pool_ids` and `node_pool_names`, which always return a list and work correctly for both single and double pool configurations.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks_node_pool_bar"></a> [aks\_node\_pool\_bar](#module\_aks\_node\_pool\_bar) | ../../kubernetes_cluster_node_pool | n/a |
| <a name="module_aks_node_pool_foo"></a> [aks\_node\_pool\_foo](#module\_aks\_node\_pool\_foo) | ../../kubernetes_cluster_node_pool | n/a |
| <a name="module_aks_overlay_snet"></a> [aks\_overlay\_snet](#module\_aks\_overlay\_snet) | ../subnet | n/a |
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_subnet_nat_gateway_association.aks_overlay_snet_nat_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscale_enabled"></a> [autoscale\_enabled](#input\_autoscale\_enabled) | (Optional): Enable autoscaling for the node pool. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_self_inbound_nsg_rule"></a> [create\_self\_inbound\_nsg\_rule](#input\_create\_self\_inbound\_nsg\_rule) | (Optional) Flag the automatic creation of self-inbound security rules. Set to true to allow internal traffic within the same security scope | `bool` | `true` | no |
| <a name="input_double_node_pool"></a> [double\_node\_pool](#input\_double\_node\_pool) | (Optional) Configuration for double foo/bar node pool setup. If 'enabled' is true, two node pools will be created with the provided configuration. 'node\_pool\_foo.active' and 'node\_pool\_bar.active' flags determine which node pool is active at deployment. Only the active node pool will have a non-zero minimum node count, while the other will be set to zero to prevent provisioning of nodes. | <pre>object({<br/>    enabled = optional(bool, false)<br/>    node_pool_foo = object({<br/>      active           = bool<br/>      version_override = optional(string, null) ## if provided, overrides the kubernetes version of the cluster for this node pool<br/>    })<br/>    node_pool_bar = object({<br/>      active           = bool<br/>      version_override = optional(string, null) ## if provided, overrides the kubernetes version of the cluster for this node pool<br/>    })<br/><br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "node_pool_bar": {<br/>    "active": false,<br/>    "version_override": null<br/>  },<br/>  "node_pool_foo": {<br/>    "active": true,<br/>    "version_override": null<br/>  }<br/>}</pre> | no |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) List of allowed cidr and name . Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string ## short name for source_address_prefixes<br/>  })</pre> | <pre>{<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All"<br/>}</pre> | no |
| <a name="input_embedded_subnet"></a> [embedded\_subnet](#input\_embedded\_subnet) | (Optional) Configuration for creating an embedded Subnet for the AKS Nodepool. If 'enabled' is true, 'vnet\_subnet\_id' must be null | <pre>object({<br/>    enabled      = bool<br/>    vnet_name    = optional(string, null)<br/>    vnet_rg_name = optional(string, null)<br/>    subnet_name  = optional(string, null)<br/>    natgw_id     = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "natgw_id": null,<br/>  "subnet_name": null,<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | (Required): Environment for which the resource will be created. | `string` | n/a | yes |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required): The name of IDH resource tier to be created. | `string` | n/a | yes |
| <a name="input_kubernetes_cluster_id"></a> [kubernetes\_cluster\_id](#input\_kubernetes\_cluster\_id) | (Required): AKS cluster id. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required): Node pool name. Must not exceed 12 characters. | `string` | n/a | yes |
| <a name="input_node_count_max"></a> [node\_count\_max](#input\_node\_count\_max) | (Required): Maximum number of nodes in the node pool. | `number` | n/a | yes |
| <a name="input_node_count_min"></a> [node\_count\_min](#input\_node\_count\_min) | (Required): Minimum number of nodes in the node pool. | `number` | n/a | yes |
| <a name="input_node_labels"></a> [node\_labels](#input\_node\_labels) | (Required): Map of labels to assign to the nodes. | `map(string)` | n/a | yes |
| <a name="input_node_tags"></a> [node\_tags](#input\_node\_tags) | (Required): Map of tags to assign to the nodes. | `map(any)` | n/a | yes |
| <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints) | (Optional): List of taints to assign to the nodes. | `list(string)` | <pre>[<br/>  ""<br/>]</pre> | no |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_os_disk_size_gb"></a> [os\_disk\_size\_gb](#input\_os\_disk\_size\_gb) | (Optional): OS disk size in GB | `number` | `null` | no |
| <a name="input_os_disk_type"></a> [os\_disk\_type](#input\_os\_disk\_type) | (Optional): Type of OS disk | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required): Product name used to identify the platform for which the resource will be created. | `string` | n/a | yes |
| <a name="input_resource_group_nsg_name"></a> [resource\_group\_nsg\_name](#input\_resource\_group\_nsg\_name) | (Optional) The name of the nsg Resource Group. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional): Map of tags to assign to the resource. | `map(any)` | n/a | yes |
| <a name="input_vnet_subnet_id"></a> [vnet\_subnet\_id](#input\_vnet\_subnet\_id) | (Optional): Subnet id for the node pool. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the AKS node pool. Deprecated in favor of node\_pool\_ids output, which returns a list of node pool IDs to accommodate multiple node pools when double\_node\_pool is enabled. |
| <a name="output_name"></a> [name](#output\_name) | Name of the AKS node pool. Deprecated in favor of node\_pool\_names output, which returns a list of node pool names to accommodate multiple node pools when double\_node\_pool is enabled. |
| <a name="output_node_pool_ids"></a> [node\_pool\_ids](#output\_node\_pool\_ids) | List of AKS node pool IDs. If double\_node\_pool is enabled, both node pool IDs are returned, otherwise only the first node pool ID is returned. |
| <a name="output_node_pool_names"></a> [node\_pool\_names](#output\_node\_pool\_names) | List of AKS node pool names. If double\_node\_pool is enabled, both node pool names are returned, otherwise only the first node pool name is returned. |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | ID of the subnet associated with the AKS node pool. If embedded\_subnet is enabled, the ID of the overlay subnet is returned, otherwise the ID of the provided virtual network subnet is returned. |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | Name of the subnet associated with the AKS node pool. If embedded\_subnet is enabled, the name of the overlay subnet is returned, otherwise an empty string is returned since the subnet name is not directly available when using an external subnet. |
<!-- END_TF_DOCS -->
