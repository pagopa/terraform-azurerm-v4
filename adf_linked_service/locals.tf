locals {
  df_integration_runtime_name = "AutoResolveIntegrationRuntime"

  az_api_type_mappings = {
    cosmosdb = {
      data_az_api_type    = "Microsoft.DocumentDB/databaseAccounts@2025-10-15"
      approve_az_api_type = "Microsoft.DocumentDB/databaseAccounts/privateEndpointConnections@2025-10-15"
    }
    storage = {
      data_az_api_type    = "Microsoft.Storage/storageAccounts@2025-08-01"
      approve_az_api_type = "Microsoft.Storage/storageAccounts/privateEndpointConnections@2025-08-01"
    }
    postgres = {
      data_az_api_type    = "Microsoft.Network/privateLinkServices@2022-09-01"
      approve_az_api_type = "Microsoft.Network/privateLinkServices/privateEndpointConnections@2022-09-01"
    }
  }
}
