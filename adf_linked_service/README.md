# ADF linked service

This module creates managed private endpoints on the given ADF instance.

To manage connection to PostgreSQL private database  it will create a linked service to a private link service that will be used as a proxy to reach the database.

Manages the following kind of private endpoints;
- private PostgreSQL databases in a private subnet (requires configuration of `adf_egress_proxy` module and `adf_egress_connection` module)
- storage blob
- CosmosDB
- private endpoints


## How to use it

```hcl
module "adf_linked_service" {
  source = "./.terraform/modules/__v4__/adf_linked_service"

  data_factory_id           = data.azurerm_data_factory.data_factory.id
  data_factory_principal_id = data.azurerm_data_factory.data_factory.identity[0].principal_id
  env_short                 = var.env_short
  
  # required for PostgreSQL private database connection
  egress_proxy_pls_id       = data.azurerm_private_link_service.adf_egress_proxy_pls.id
  
  # optional
  adf_linked_service_postgresql = {
    "idpay-db" = {
      key_vault_id          = data.azurerm_key_vault.domain_kv.id
      host                  = trimsuffix(module.idpay_pgflex[0].private_fqdn, ".") # to remove trailing dot included in fqdn
      port                  = "5432"
      database_name         = local.idpay_postgresql_database_name
      username              = azurerm_key_vault_secret.idpay_postgres_admin_user[0].value
      password_secret_name  = azurerm_key_vault_secret.idpay_postgres_admin_password[0].name
    }
  }
  
  # optional
  adf_linked_service_cosmos = {
    "my-db" = {
      connection_string = azurerm_key_vault_secret.my_conn_string.value
      account_name      = azurerm_cosmosdb_account.my_cosmos.name
      database          = "db"
    }
  }
  # optional  
  adf_linked_service_blob = {
    "my-blob" = {
      connection_string = azurerm_key_vault_secret.my_blob_conn_string.value
    }
  }
  
  # optional
  adf_managed_private_endpoint = {
    AfmMarketplaceSql = {
      target_resource_id = data.azurerm_cosmosdb_account.afm_cosmos_account.id
      fqdns              = null
      subresource_name   = "Sql"
      type               = "cosmosdb"
    }
  }

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adf_linked_service_postgresql"></a> [adf\_linked\_service\_postgresql](#input\_adf\_linked\_service\_postgresql) | (Optional): A map of linked service configurations for PostgreSQL databases. | <pre>map(object({<br/>    key_vault_id         = string # ID del Key Vault da cui recuperare la password di accesso al db.<br/>    host                 = string # hostname privato del server PostgreSQL, esposto sul proxy_adf.<br/>    port                 = string # porta del server PostgreSQL esposta dal proxy_adf (può non coincidere con la porta nativa del server).<br/>    database_name        = string # nome del database PostgreSQL.<br/>    username             = string # username per l'autenticazione al database PostgreSQL.<br/>    password_secret_name = string # nome del segreto contenente la password per l'autenticazione.<br/>  }))</pre> | `{}` | no |
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
