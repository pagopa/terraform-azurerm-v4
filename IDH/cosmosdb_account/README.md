# Cosmos DB account

This module allow the setup of a cosmos db account

## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource` available for this module

## How to use it

### CosmosDB Mongo version

```ts
module "cosmos_idh_mongo" {
  source                     = ""./.terraform/modules/__v4__/IDH/cosmosdb_account"
  domain                     = "mydomain"
  name                       = "my-cosmos-db-account-name"
  resource_group_name        = "my-cosmos-db-account-resource-group"
  location                   = var.location
  
  main_geo_location_location = "my-replication-location"
  
  product_name                     = "myprefix" # Es. pagoapa
  env                        = "myenv" # Es. dev
  idh_resource               = "cosmos_mongo6" 
}

```

### CosmosDB SQL version

```ts
module "cosmos_idh_sql" {
  source                     = ""./.terraform/modules/__v4__/IDH/cosmosdb_account"
  domain                     = "mydomain"
  name                       = "my-cosmos-db-account-name"
  resource_group_name        = "my-cosmos-db-account-resource-group"
  location                   = var.location
  
  main_geo_location_location = "my-replication-location"
  
  product_name                     = "myprefix" # Es. pagoapa
  env                        = "myenv" # Es. dev
  idh_resource               = "cosmos_sql6" 
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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cosmosdb_account"></a> [cosmosdb\_account](#module\_cosmosdb\_account) | ../../cosmosdb_account | n/a |
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_geo_locations"></a> [additional\_geo\_locations](#input\_additional\_geo\_locations) | Specifies a list of additional geo\_location resources, used to define where data should be replicated. | <pre>list(object({<br/>    location          = string<br/>    failover_priority = number<br/>    zone_redundant    = bool<br/>  }))</pre> | `[]` | no |
| <a name="input_allowed_virtual_network_subnet_ids"></a> [allowed\_virtual\_network\_subnet\_ids](#input\_allowed\_virtual\_network\_subnet\_ids) | The subnets id that are allowed to access this CosmosDB account. | `list(string)` | `[]` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | (Optional) Specifies the domain of the CosmosDB Account. | `string` | n/a | yes |
| <a name="input_enable_automatic_failover"></a> [enable\_automatic\_failover](#input\_enable\_automatic\_failover) | Enable automatic fail over for this Cosmos DB account. | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name of IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_ip_range"></a> [ip\_range](#input\_ip\_range) | The set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IP's for a given database account. | `list(string)` | `null` | no |
| <a name="input_key_vault_key_id"></a> [key\_vault\_key\_id](#input\_key\_vault\_key\_id) | (Optional) A versionless Key Vault Key ID for CMK encryption. Changing this forces a new resource to be created. When referencing an azurerm\_key\_vault\_key resource, use versionless\_id instead of id | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_main_geo_location_location"></a> [main\_geo\_location\_location](#input\_main\_geo\_location\_location) | (Required) The name of the Azure region to host replicated data. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_private_endpoint_config"></a> [private\_endpoint\_config](#input\_private\_endpoint\_config) | Configuration for private endpoint and DNS zones for CosmosDB | <pre>object({<br/>    subnet_id                         = string<br/>    private_dns_zone_sql_ids          = list(string)<br/>    private_dns_zone_table_ids        = list(string)<br/>    private_dns_zone_mongo_ids        = list(string)<br/>    private_dns_zone_cassandra_ids    = list(string)<br/>    enabled                           = bool<br/>    name_sql                          = string<br/>    service_connection_name_sql       = string<br/>    name_mongo                        = string<br/>    service_connection_name_mongo     = string<br/>    name_cassandra                    = string<br/>    service_connection_name_cassandra = string<br/>    name_table                        = string<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "name_cassandra": null,<br/>  "name_mongo": null,<br/>  "name_sql": null,<br/>  "name_table": null,<br/>  "private_dns_zone_cassandra_ids": [],<br/>  "private_dns_zone_mongo_ids": [],<br/>  "private_dns_zone_sql_ids": [],<br/>  "private_dns_zone_table_ids": [],<br/>  "service_connection_name_cassandra": null,<br/>  "service_connection_name_mongo": null,<br/>  "service_connection_name_sql": null,<br/>  "subnet_id": null<br/>}</pre> | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | n/a | `string` | n/a | yes |
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
