# ADF egress proxy

This module creates a proxy that can be used by ADX clusters to reach private PostgreSQL databases in a private subnet. The proxy is deployed in a dedicated subnet and is associated with a NAT Gateway to allow outbound traffic to the internet.


## How to use it

### Basic usage – single node pool with external subnet

```hcl
module "adx_egress_proxy" {
  source = "./.terraform/modules/__v4__/adf_egress_proxy"

 

}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.df_connection_linked_service_postgres](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource_action.approve_privatelink_private_endpoint_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action) | resource |
| [azapi_resource_action.df_connection_approve_private_endpoint_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action) | resource |
| [azurerm_data_factory_linked_custom_service.df_connection_linked_service_cosmosdb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_linked_custom_service) | resource |
| [azurerm_data_factory_linked_service_azure_blob_storage.df_connection_linked_service_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_linked_service_azure_blob_storage) | resource |
| [azurerm_data_factory_linked_service_key_vault.df_connection_linked_service_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_linked_service_key_vault) | resource |
| [azurerm_data_factory_managed_private_endpoint.df_connection_managed_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_managed_private_endpoint) | resource |
| [azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_managed_private_endpoint) | resource |
| [azurerm_key_vault_access_policy.df_connection_access_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azapi_resource.df_connection_privatelink_private_endpoint_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |
| [azapi_resource.privatelink_private_endpoint_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault_secret.df_connection_postgres_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.df_connection_postgres_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.df_connection_postgres_port](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.df_connection_postgres_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adf_linked_service_postgresql"></a> [adf\_linked\_service\_postgresql](#input\_adf\_linked\_service\_postgresql) | (Optional): A map of linked service configurations for PostgreSQL databases. | <pre>map(object({<br/>    key_vault_id         = string #ID del Key Vault da cui recuperare la password di accesso al db.<br/>    host                 = string # hostname raggiungibile privatamente del server PostgreSQL.<br/>    port                 = string # porta del server PostgreSQL.<br/>    database_name        = string # nome del database PostgreSQL.<br/>    username             = string # username per l'autenticazione al database PostgreSQL.<br/>    password_secret_name = string #nome del segreto contenente la password per l'autenticazione.<br/>  }))</pre> | `{}` | no |
| <a name="input_adf_linked_services_blob"></a> [adf\_linked\_services\_blob](#input\_adf\_linked\_services\_blob) | (Optional): A map of linked service configurations for Azure Blob Storage accounts. Each entry should contain a connection string. | <pre>map(object({<br/>    connection_string = string #stringa di connessione all'account di archiviazione Azure Blob Storage.<br/>  }))</pre> | `{}` | no |
| <a name="input_adf_linked_services_cosmosdb"></a> [adf\_linked\_services\_cosmosdb](#input\_adf\_linked\_services\_cosmosdb) | (Optional): A map of linked service configurations for Cosmos DB accounts. Each entry should contain a connection string and the corresponding database name. | <pre>map(object({<br/>    connection_string = string #connection string dell'account Cosmos DB.<br/>    account_name      = string #nome dell'account Cosmos DB.<br/>    database          = string #nome del database Cosmos DB a cui collegarsi.<br/>  }))</pre> | `{}` | no |
| <a name="input_adf_managed_private_endpoint"></a> [adf\_managed\_private\_endpoint](#input\_adf\_managed\_private\_endpoint) | (Optional): A map of managed private endpoint configurations for Azure Data Factory. Each entry should contain the target resource ID, FQDNs, subresource name, and type. | <pre>map(object({<br/>    target_resource_id = string       #ID della risorsa di destinazione.<br/>    fqdns              = list(string) #lista di FQDN (Fully Qualified Domain Names) recuperati da Key Vault, utilizzati per la risoluzione DNS dell'endpoint privato.<br/>    subresource_name   = string       #nome della sottorisorsa per cui è necessario approvare la connessione (opzionale, dipende dal servizio di destinazione).<br/>    type               = string       #tipo di risorsa di destinazione, utilizzato per mappare correttamente le API di Azure durante l'approvazione della connessione privata.<br/>  }))</pre> | `{}` | no |
| <a name="input_data_factory_id"></a> [data\_factory\_id](#input\_data\_factory\_id) | (Required): The ID of the Azure Data Factory instance to which the managed private endpoint will be associated. | `string` | n/a | yes |
| <a name="input_data_factory_principal_id"></a> [data\_factory\_principal\_id](#input\_data\_factory\_principal\_id) | (Required): The principal ID of the Azure Data Factory instance to which the managed private endpoint will be associated. | `string` | n/a | yes |
| <a name="input_egress_proxy_pls_id"></a> [egress\_proxy\_pls\_id](#input\_egress\_proxy\_pls\_id) | (Required): The ID of the Private Link Service (PLS) for the egress proxy to which the managed private endpoint will connect. | `string` | n/a | yes |
| <a name="input_env_short"></a> [env\_short](#input\_env\_short) | (Required): Short environment name (e.g., 'd', 'u', 'p'). | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
