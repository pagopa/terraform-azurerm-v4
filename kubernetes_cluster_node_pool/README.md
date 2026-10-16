# kubernetes_cluster_node_pool

## Overview

Creates an additional (user) node pool on an existing AKS cluster (`azurerm_kubernetes_cluster_node_pool`).

Main behaviours:

- Linux nodes only, no public IP on nodes, drain timeout of 30 minutes during upgrades.
- Supports autoscaling (`node_count_min` / `node_count_max`), zones, labels, taints, custom subnet and surge settings.
- **Node count preservation**: the module reads the cluster (`data.azurerm_kubernetes_cluster`) and looks up the current node count of the pool by name. If the pool already exists, its current count is used as `node_count`, avoiding resets of the autoscaler's value; if it doesn't exist yet, `node_count_min` is used. Reading the cluster (and not the pool) means the lookup never fails for pools not yet created.
- `override_node_count` forces a specific node count, even with autoscaling enabled.
- `temporary_name_for_rotation` is generated automatically to allow in-place node pool changes that require rotation.

## Examples

```hcl
module "node_pool" {
  source = "./.terraform/modules/__v4__/kubernetes_cluster_node_pool"

  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vnet_subnet_id        = azurerm_subnet.aks.id

  vm_size         = "Standard_D4ds_v5"
  os_disk_type    = "Ephemeral"
  os_disk_size_gb = 128
  zones           = ["1", "2", "3"]

  autoscale_enabled = true
  node_count_min    = 2
  node_count_max    = 6

  node_labels = { "workload" = "apps" }
  node_taints = ["dedicated=apps:NoSchedule"]

  node_tags = {}
  tags      = { environment = "dev" }
}
```

Force a fixed node count:

```hcl
override_node_count = {
  enabled = true
  count   = 3
}
```

## Notes

- `name` must not exceed 12 characters.
- `kubernetes_cluster_id` must be a full AKS resource ID: cluster name and resource group are parsed from it.
- The cluster must exist when the module is planned (it is read via a data source).
- Changing the pool's node count outside Terraform is reflected on the next apply, since the current count is read from the cluster.

## Troubleshooting

- **Index error on `cluster_id_parts`**: `kubernetes_cluster_id` is not a valid AKS resource ID (or is unknown at plan time).
- **Data source fails with cluster not found**: the cluster is not created yet; create it in a previous apply or add `depends_on` appropriately.
- **Node count differs from `node_count_min`**: expected for existing pools, the current count is preserved; use `override_node_count` to change it.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster_node_pool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [random_string.rotation](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_kubernetes_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscale_enabled"></a> [autoscale\_enabled](#input\_autoscale\_enabled) | (Optional): Enable autoscaling for the node pool | `bool` | `true` | no |
| <a name="input_enable_host_encryption"></a> [enable\_host\_encryption](#input\_enable\_host\_encryption) | (Optional): Enable host encryption | `bool` | `false` | no |
| <a name="input_kubernetes_cluster_id"></a> [kubernetes\_cluster\_id](#input\_kubernetes\_cluster\_id) | (Required): The ID of the AKS cluster | `string` | n/a | yes |
| <a name="input_max_pods"></a> [max\_pods](#input\_max\_pods) | (Optional): Maximum pods per node | `number` | `250` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required): Node pool name. Must not exceed 12 characters. | `string` | n/a | yes |
| <a name="input_node_count_max"></a> [node\_count\_max](#input\_node\_count\_max) | (Required): Maximum node count | `number` | n/a | yes |
| <a name="input_node_count_min"></a> [node\_count\_min](#input\_node\_count\_min) | (Required): Minimum node count | `number` | n/a | yes |
| <a name="input_node_labels"></a> [node\_labels](#input\_node\_labels) | (Optional): Node labels | `map(string)` | `{}` | no |
| <a name="input_node_tags"></a> [node\_tags](#input\_node\_tags) | (Required): Additional tags for the node pool. | `map(any)` | n/a | yes |
| <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints) | (Optional): List of node taints. | `list(string)` | `[]` | no |
| <a name="input_orchestrator_version"></a> [orchestrator\_version](#input\_orchestrator\_version) | (Optional): Kubernetes version for the node pool. If not specified, it will inherit the cluster's Kubernetes version. | `string` | `null` | no |
| <a name="input_os_disk_size_gb"></a> [os\_disk\_size\_gb](#input\_os\_disk\_size\_gb) | (Optional): OS disk size in GB | `number` | `128` | no |
| <a name="input_os_disk_type"></a> [os\_disk\_type](#input\_os\_disk\_type) | (Required): Type of OS disk | `string` | n/a | yes |
| <a name="input_override_node_count"></a> [override\_node\_count](#input\_override\_node\_count) | (Optional): Override the node count for the node pool. Affects the pool even if autoscaling is enabled. If enabled, the node count will be set to the specified count. | <pre>object({<br/>    enabled = bool<br/>    count   = number<br/>  })</pre> | <pre>{<br/>  "count": 0,<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Required): Base tags. | `map(any)` | n/a | yes |
| <a name="input_ultra_ssd_enabled"></a> [ultra\_ssd\_enabled](#input\_ultra\_ssd\_enabled) | (Optional): Enable Ultra SSD | `bool` | `false` | no |
| <a name="input_upgrade_settings_max_surge"></a> [upgrade\_settings\_max\_surge](#input\_upgrade\_settings\_max\_surge) | (Optional): Max surge during upgrade. | `string` | `"33%"` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | (Required): VM size for the nodes | `string` | n/a | yes |
| <a name="input_vnet_subnet_id"></a> [vnet\_subnet\_id](#input\_vnet\_subnet\_id) | (Required): Subnet ID for the node pool. | `string` | n/a | yes |
| <a name="input_zones"></a> [zones](#input\_zones) | (Optional): Availability zones | `list(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
<!-- END_TF_DOCS -->
