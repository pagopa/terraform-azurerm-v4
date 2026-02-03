output "id" {
  description = "The id of the CosmosDB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "name" {
  description = "The name of the CosmosDB created."
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "The endpoint used to connect to the CosmosDB account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "write_endpoints" {
  description = "A list of write endpoints available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.this.write_endpoints
}

output "read_endpoints" {
  description = "A list of read endpoints available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.this.read_endpoints
}

# @deprecated
output "primary_master_key" {
  value     = azurerm_cosmosdb_account.this.primary_key
  sensitive = true
}

output "primary_key" {
  value     = azurerm_cosmosdb_account.this.primary_key
  sensitive = true
}

output "secondary_key" {
  value     = azurerm_cosmosdb_account.this.secondary_key
  sensitive = true
}

# @deprecated
output "primary_readonly_master_key" {
  value     = azurerm_cosmosdb_account.this.primary_readonly_key
  sensitive = true
}

output "primary_readonly_key" {
  value     = azurerm_cosmosdb_account.this.primary_readonly_key
  sensitive = true
}

output "primary_connection_strings" {
  value     = azurerm_cosmosdb_account.this.primary_mongodb_connection_string
  sensitive = true
}

output "secondary_connection_strings" {
  value     = azurerm_cosmosdb_account.this.secondary_mongodb_connection_string
  sensitive = true
}

output "principal_id" {
  value = azurerm_cosmosdb_account.this.identity.0.principal_id
}


output "primary_sql_connection_strings" {
  value     = azurerm_cosmosdb_account.this.primary_sql_connection_string
  sensitive = true
}


output "secondary_sql_connection_strings" {
  value     = azurerm_cosmosdb_account.this.secondary_sql_connection_string
  sensitive = true
}

output "legacy_primary_sql_connection_strings" {
  value     = "DefaultEndpointsProtocol=https;AccountName=${var.name};AccountKey=${azurerm_cosmosdb_account.this.primary_key};TableEndpoint=https://${var.name}.table.cosmos.azure.com:443/;"
  sensitive = true
}

output "legacy_secondary_sql_connection_strings" {
  value     = "DefaultEndpointsProtocol=https;AccountName=${var.name};AccountKey=${azurerm_cosmosdb_account.this.secondary_key};TableEndpoint=https://${var.name}.table.cosmos.azure.com:443/;"
  sensitive = true
}

output "primary_connection_string_readonly" {
  value     = azurerm_cosmosdb_account.this.primary_readonly_mongodb_connection_string
  sensitive = true
}

output "primary_sql_connection_string_readonly" {
  value     = azurerm_cosmosdb_account.this.primary_readonly_sql_connection_string
  sensitive = true
}
