# Cosmos DB account

This module allow the setup of a cosmos db account

## Architecture

![This is an image](./docs/module-arch.drawio.png)

## How to use

### CosmosDB Mongo version

```ts
module "cosmos_mongo" {
  source   = "git::https://github.com/pagopa/terraform-azurerm-v3.git//cosmosdb_account?ref=v8.8.0"
  name     = "${local.project}-cosmos-mongo"
  location = var.location
  domain   = var.domain

  resource_group_name  = azurerm_resource_group.cosmos_mongo_rg[0].name
  offer_type           = "Standard"
  kind                 = "MongoDB"
  capabilities         = ["EnableMongo"]
  mongo_server_version = "4.0"

  main_geo_location_zone_redundant = false

  enable_free_tier          = false
  enable_automatic_failover = true

  consistency_policy = {
    consistency_level       = "Strong"
    max_interval_in_seconds = null
    max_staleness_prefix    = null
  }

  main_geo_location_location = "northeurope"

  additional_geo_locations = [
    {
      location          = "westeurope"
      failover_priority = 1
      zone_redundant    = false
    }
  ]

  backup_continuous_enabled = true

  is_virtual_network_filter_enabled = true

  ip_range = ""

  allowed_virtual_network_subnet_ids = [
    module.private_endpoints_snet.id
  ]

  # private endpoint
  private_endpoint_name    = "${local.project}-cosmos-mongo-sql-endpoint"
  private_endpoint_enabled = true
  subnet_id                = module.private_endpoints_snet.id
  private_dns_zone_ids     = [data.azurerm_private_dns_zone.internal.id]

  tags = var.tags

}
```

### CosmosDB SQL version

```ts
module "cosmos_core" {
  source   = "git::https://github.com/pagopa/terraform-azurerm-v3.git//cosmosdb_account?ref=v8.8.0"
  name     = "${local.project}-cosmos-core"
  location = var.location
  domain   = var.domain

  resource_group_name = azurerm_resource_group.cosmos_rg[0].name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  main_geo_location_zone_redundant = false

  enable_free_tier          = false
  enable_automatic_failover = true

  consistency_policy = {
    consistency_level       = "Strong"
    max_interval_in_seconds = null
    max_staleness_prefix    = null
  }

  main_geo_location_location = "northeurope"

  additional_geo_locations = [
    {
      location          = "westeurope"
      failover_priority = 1
      zone_redundant    = false
    }
  ]

  backup_continuous_enabled = true

  is_virtual_network_filter_enabled = true

  ip_range = ""

  allowed_virtual_network_subnet_ids = [
    module.private_endpoints_snet.id
  ]

  # private endpoint
  private_endpoint_name    = "${local.project}-cosmos-core-sql-endpoint"
  private_endpoint_enabled = true
  subnet_id                = module.private_endpoints_snet.id
  private_dns_zone_ids     = [data.azurerm_private_dns_zone.internal.id]

  tags = var.tags

}
```


## Migration from v2

1️⃣ Arguments changed:

* The field `capabilities` will no longer accept the value `EnableAnalyticalStorage`.
* `primary_master_key` -> `primary_key`.
* `secondary_master_key` -> `secondary_key`.
* `primary_readonly_master_key` -> `primary_readonly_key`.
* `secondary_readonly_master_key` -> `secondary_readonly_key`.

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
| <a name="module_cosmosdb_account"></a> [cosmosdb\_account](#module\_cosmosdb\_account) | ../../cosmosdb_account | n/a |
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../00_idh_loader | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_geo_locations"></a> [additional\_geo\_locations](#input\_additional\_geo\_locations) | Specifies a list of additional geo\_location resources, used to define where data should be replicated. | <pre>list(object({<br/>    location          = string<br/>    failover_priority = number<br/>    zone_redundant    = bool<br/>  }))</pre> | `[]` | no |
| <a name="input_allowed_virtual_network_subnet_ids"></a> [allowed\_virtual\_network\_subnet\_ids](#input\_allowed\_virtual\_network\_subnet\_ids) | The subnets id that are allowed to access this CosmosDB account. | `list(string)` | `[]` | no |
| <a name="input_burst_capacity_enabled"></a> [burst\_capacity\_enabled](#input\_burst\_capacity\_enabled) | (Optional) Enable burst capacity for this Cosmos DB account. Defaults to false. | `bool` | `false` | no |
| <a name="input_capabilities"></a> [capabilities](#input\_capabilities) | The capabilities which should be enabled for this Cosmos DB account. | `list(string)` | `[]` | no |
| <a name="input_consistency_policy"></a> [consistency\_policy](#input\_consistency\_policy) | Specifies a consistency\_policy resource, used to define the consistency policy for this CosmosDB account. | <pre>object({<br/>    consistency_level       = string<br/>    max_interval_in_seconds = number<br/>    max_staleness_prefix    = number<br/>  })</pre> | <pre>{<br/>  "consistency_level": "BoundedStaleness",<br/>  "max_interval_in_seconds": 5,<br/>  "max_staleness_prefix": 100<br/>}</pre> | no |
| <a name="input_domain"></a> [domain](#input\_domain) | (Optional) Specifies the domain of the CosmosDB Account. | `string` | n/a | yes |
| <a name="input_enable_automatic_failover"></a> [enable\_automatic\_failover](#input\_enable\_automatic\_failover) | Enable automatic fail over for this Cosmos DB account. | `bool` | `true` | no |
| <a name="input_enable_free_tier"></a> [enable\_free\_tier](#input\_enable\_free\_tier) | Enable Free Tier pricing option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_enable_provisioned_throughput_exceeded_alert"></a> [enable\_provisioned\_throughput\_exceeded\_alert](#input\_enable\_provisioned\_throughput\_exceeded\_alert) | Enable the Provisioned Throughput Exceeded alert. Default is true | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_idh_resource"></a> [idh\_resource](#input\_idh\_resource) | (Required) The name of IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_ip_range"></a> [ip\_range](#input\_ip\_range) | The set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IP's for a given database account. | `list(string)` | `null` | no |
| <a name="input_key_vault_key_id"></a> [key\_vault\_key\_id](#input\_key\_vault\_key\_id) | (Optional) A versionless Key Vault Key ID for CMK encryption. Changing this forces a new resource to be created. When referencing an azurerm\_key\_vault\_key resource, use versionless\_id instead of id | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_main_geo_location_location"></a> [main\_geo\_location\_location](#input\_main\_geo\_location\_location) | (Required) The name of the Azure region to host replicated data. | `string` | n/a | yes |
| <a name="input_minimal_tls_version"></a> [minimal\_tls\_version](#input\_minimal\_tls\_version) | (Optional) Specifies the minimal TLS version for the CosmosDB account. Allowed values: Tls, Tls11, Tls12. | `string` | `"Tls12"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_offer_type"></a> [offer\_type](#input\_offer\_type) | The CosmosDB account offer type. Currently can only be set to 'Standard'. | `string` | `"Standard"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_private_endpoint_config"></a> [private\_endpoint\_config](#input\_private\_endpoint\_config) | Configuration for private endpoint and DNS zones for CosmosDB | <pre>object({<br/>    subnet_id                         = string<br/>    private_dns_zone_sql_ids          = list(string)<br/>    private_dns_zone_table_ids        = list(string)<br/>    private_dns_zone_mongo_ids        = list(string)<br/>    private_dns_zone_cassandra_ids    = list(string)<br/>    enabled                           = bool<br/>    name_sql                          = string<br/>    service_connection_name_sql       = string<br/>    name_mongo                        = string<br/>    service_connection_name_mongo     = string<br/>    name_cassandra                    = string<br/>    service_connection_name_cassandra = string<br/>    name_table                        = string<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "name_cassandra": null,<br/>  "name_mongo": null,<br/>  "name_sql": null,<br/>  "name_table": null,<br/>  "private_dns_zone_cassandra_ids": [],<br/>  "private_dns_zone_mongo_ids": [],<br/>  "private_dns_zone_sql_ids": [],<br/>  "private_dns_zone_table_ids": [],<br/>  "service_connection_name_cassandra": null,<br/>  "service_connection_name_mongo": null,<br/>  "service_connection_name_sql": null,<br/>  "subnet_id": null<br/>}</pre> | no |
| <a name="input_provisioned_throughput_exceeded_threshold"></a> [provisioned\_throughput\_exceeded\_threshold](#input\_provisioned\_throughput\_exceeded\_threshold) | The Provisioned Throughput Exceeded threshold. If metric average is over this value, the alert will be triggered. Default is 0, we want to act as soon as possible. | `number` | `0` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group in which the CosmosDB Account is created. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Used only for private endpoints | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | The endpoint used to connect to the CosmosDB account. |
| <a name="output_id"></a> [id](#output\_id) | The id of the CosmosDB account. |
| <a name="output_name"></a> [name](#output\_name) | The name of the CosmosDB created. |
| <a name="output_primary_connection_strings"></a> [primary\_connection\_strings](#output\_primary\_connection\_strings) | n/a |
| <a name="output_primary_key"></a> [primary\_key](#output\_primary\_key) | n/a |
| <a name="output_primary_master_key"></a> [primary\_master\_key](#output\_primary\_master\_key) | @deprecated |
| <a name="output_primary_readonly_key"></a> [primary\_readonly\_key](#output\_primary\_readonly\_key) | n/a |
| <a name="output_primary_readonly_master_key"></a> [primary\_readonly\_master\_key](#output\_primary\_readonly\_master\_key) | @deprecated |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | n/a |
| <a name="output_read_endpoints"></a> [read\_endpoints](#output\_read\_endpoints) | A list of read endpoints available for CosmosDB account. |
| <a name="output_secondary_connection_strings"></a> [secondary\_connection\_strings](#output\_secondary\_connection\_strings) | n/a |
| <a name="output_secondary_key"></a> [secondary\_key](#output\_secondary\_key) | n/a |
| <a name="output_write_endpoints"></a> [write\_endpoints](#output\_write\_endpoints) | A list of write endpoints available for CosmosDB account. |
<!-- END_TF_DOCS -->
