# Cosmos DB sql container

This module allow the setup of a cosmos db sql container

## Architecture

![This is an image](./docs/module-arch.drawio.png)

## How to use

```ts
locals {
  core_cosmosdb_containers = [

    {
      name               = "user-cores"
      partition_key_path = "/fiscalCode"
      autoscale_settings = {
        max_throughput = 6000
      },
    },
    {
      name               = "user-eyca-cards"
      partition_key_path = "/fiscalCode"
      autoscale_settings = {
        max_throughput = 6000
      }
      indexing_policy    = {
        composite_indexes = [
          [
            { path: "/field1" },
            { path: "/field10" },
          ],
          [
            { path: "/field2", order: "descending" },
            { path: "/nested/field" },
            { path: "/field3", order: "ascending" },
          ]
        ]
      }
    },

  ]
}


module "core_cosmosdb_containers" {
  source   = "git::https://github.com/pagopa/terraform-azurerm-v3.git//cosmosdb_sql_container?ref=v8.8.0"
  for_each = { for c in local.core_cosmosdb_containers : c.name => c }

  name                = each.value.name
  resource_group_name = azurerm_resource_group.cosmos_rg[0].name
  account_name        = module.cosmos_core.name
  database_name       = module.core_cosmos_db.name
  partition_key_path  = each.value.partition_key_path
  throughput          = lookup(each.value, "throughput", null)
  indexing_policy     = lookup(each.value, "indexing_policy", null)}

  autoscale_settings = lookup(each.value, "autoscale_settings", null)

}

```

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
| [azurerm_cosmosdb_sql_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | The name of the Cosmos DB Account to create the container within. | `string` | n/a | yes |
| <a name="input_autoscale_settings"></a> [autoscale\_settings](#input\_autoscale\_settings) | Autoscale settings for collection | <pre>object({<br/>    max_throughput = number<br/>  })</pre> | `null` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the Cosmos DB SQL Database to create the container within. | `string` | n/a | yes |
| <a name="input_default_ttl"></a> [default\_ttl](#input\_default\_ttl) | The default time to live of SQL container. If missing, items are not expired automatically. | `number` | `null` | no |
| <a name="input_indexing_policy"></a> [indexing\_policy](#input\_indexing\_policy) | The configuration of indexes on collection | <pre>object({<br/>    # The indexing strategy. Valid options are: consistent, none<br/>    indexing_mode = optional(string, "consistent"),<br/><br/>    # One or more paths for which the indexing behaviour applies to. Either included_path or excluded_path must contain the all-path string ('/*')<br/>    included_paths = optional(list(string), ["/*"]),<br/><br/>    # One or more paths that are excluded from indexing. Either included_path or excluded_path must contain the all-path string ('/*')<br/>    excluded_paths = optional(list(string), []),<br/><br/>    # One or more path that define complex indexes. There can be multiple composite indexes on same indexing policy<br/>    composite_indexes = optional(list(list(object(<br/>      {<br/>        # The path of the field to be included in the composite index<br/>        path = string<br/><br/>        # The sort of single field in indexing structure. Valid options are: ascending, descending<br/>        order = optional(string, "ascending")<br/>      }<br/>    ))), []),<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cosmos DB instance. | `string` | n/a | yes |
| <a name="input_partition_key_paths"></a> [partition\_key\_paths](#input\_partition\_key\_paths) | Define a partition key. | `list(string)` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which the Cosmos DB SQL | `string` | n/a | yes |
| <a name="input_throughput"></a> [throughput](#input\_throughput) | The throughput of SQL container (RU/s). Must be set in increments of 100. The minimum value is 400. | `number` | `null` | no |
| <a name="input_unique_key_paths"></a> [unique\_key\_paths](#input\_unique\_key\_paths) | A list of paths to use for this unique key. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
<!-- END_TF_DOCS -->
