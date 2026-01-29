output "id" {
  description = "The id of the CosmosDB account."
  value       = module.cosmosdb_account.id
}

output "name" {
  description = "The name of the CosmosDB created."
  value       = module.cosmosdb_account.name
}

output "endpoint" {
  description = "The endpoint used to connect to the CosmosDB account."
  value       = module.cosmosdb_account.endpoint
}

output "write_endpoints" {
  description = "A list of write endpoints available for CosmosDB account."
  value       = module.cosmosdb_account.write_endpoints
}

output "read_endpoints" {
  description = "A list of read endpoints available for CosmosDB account."
  value       = module.cosmosdb_account.read_endpoints
}

# @deprecated
output "primary_master_key" {
  value     = module.cosmosdb_account.primary_key
  sensitive = true
}

output "primary_key" {
  value     = module.cosmosdb_account.primary_key
  sensitive = true
}

output "secondary_key" {
  value     = module.cosmosdb_account.secondary_key
  sensitive = true
}

# @deprecated
output "primary_readonly_master_key" {
  value     = module.cosmosdb_account.primary_readonly_key
  sensitive = true
}

output "primary_readonly_key" {
  value     = module.cosmosdb_account.primary_readonly_key
  sensitive = true
}

output "primary_connection_strings" {
  value     = module.cosmosdb_account.primary_connection_strings
  sensitive = true
}

output "secondary_connection_strings" {
  value     = module.cosmosdb_account.secondary_connection_strings
  sensitive = true
}


output "primary_sql_connection_strings" {
  value     = module.cosmosdb_account.primary_sql_connection_strings
  sensitive = true
}



output "secondary_sql_connection_strings" {
  value     = module.cosmosdb_account.secondary_sql_connection_strings
  sensitive = true
}

output "principal_id" {
  value = module.cosmosdb_account.principal_id
}

output "legacy_primary_sql_connection_strings" {
  value     = module.cosmosdb_account.legacy_primary_sql_connection_strings
  sensitive = true
}

output "legacy_secondary_sql_connection_strings" {
  value     = module.cosmosdb_account.legacy_secondary_sql_connection_strings
  sensitive = true
}
