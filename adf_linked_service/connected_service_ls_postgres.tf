resource "azurerm_data_factory_managed_private_endpoint" "proxy_private_endpoint" {
  name               = "AzureDataFactoryToVMSSProxy"
  data_factory_id    = var.data_factory_id
  target_resource_id = var.egress_proxy_pls_id
  fqdns              = [for pg in var.adf_linked_service_postgresql : pg.host]
}


data "azapi_resource" "privatelink_private_endpoint_connection" {
  type                   = "Microsoft.Network/privateLinkServices@2022-09-01"
  resource_id            = var.egress_proxy_pls_id
  response_export_values = ["properties.privateEndpointConnections."]

  depends_on = [
    azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint
  ]
}

locals {
  privatelink_private_endpoint_connection_name = data.azapi_resource.privatelink_private_endpoint_connection.output.properties.privateEndpointConnections[0].name
}


resource "azapi_resource_action" "approve_privatelink_private_endpoint_connection" {
  type        = "Microsoft.Network/privateLinkServices/privateEndpointConnections@2022-09-01"
  resource_id = "${var.egress_proxy_pls_id}/privateEndpointConnections/${local.privatelink_private_endpoint_connection_name}"
  method      = "PUT"

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved via Terraform - ${azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint.name}" # To identify which managed private endpoint this connection belongs to we add the managed private endpoint name to the description
        status      = "Approved"
      }
    }
  }
}

resource "azurerm_key_vault_access_policy" "df_connection_access_kv" {
  for_each     = var.adf_linked_service_postgresql
  key_vault_id = each.value.key_vault_id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = var.data_factory_principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_data_factory_linked_service_key_vault" "df_connection_linked_service_key_vault" {
  for_each        = var.adf_linked_service_postgresql
  name            = "${each.key}-${var.env_short}-key-vault"
  data_factory_id = var.data_factory_id
  key_vault_id    = each.value.key_vault_id
}


resource "azapi_resource" "df_connection_linked_service_postgres" {
  for_each  = var.adf_linked_service_postgresql
  type      = "Microsoft.DataFactory/factories/linkedservices@2018-06-01"
  name      = "${each.key}-postgres-${var.env_short}-ls"
  parent_id = var.data_factory_id

  body = {
    properties = {
      annotations = []
      connectVia = {
        parameters    = {}
        referenceName = local.df_integration_runtime_name
        type          = "IntegrationRuntimeReference"
      }
      type = "AzurePostgreSql"
      typeProperties = {
        connectionString = "Host=${each.value.host};Port=${each.value.port};Database=${each.value.database_name};UID=${each.value.username};EncryptionMethod=1;ValidateServerCertificate=1"
        password = {
          type = "AzureKeyVaultSecret"
          store = {
            referenceName = azurerm_data_factory_linked_service_key_vault.df_connection_linked_service_key_vault[each.key].name
            type          = "LinkedServiceReference"
          }
          secretName = each.value.password_secret_name
        }
      }
    }
  }
}
