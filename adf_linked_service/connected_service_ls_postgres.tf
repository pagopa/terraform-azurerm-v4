

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
