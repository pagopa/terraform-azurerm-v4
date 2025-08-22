output "endpoint_id" {
  value = azurerm_cdn_frontdoor_endpoint.this.id
}

output "id" {
  value       = azurerm_cdn_frontdoor_endpoint.this.id
  description = "Deprecated, use endpoint_id instead."
}

output "name" {
  value = azurerm_cdn_frontdoor_endpoint.this.name
}

output "profile_id" {
  value = azurerm_cdn_frontdoor_profile.this.id
}

output "hostname" {
  value = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "fqdn" {
  value = azurerm_cdn_frontdoor_endpoint.this.host_name
}

# Storage outputs
output "storage_id" {
  value = module.cdn_storage_account.id
}

output "storage_primary_connection_string" {
  value     = module.cdn_storage_account.primary_connection_string
  sensitive = true
}

output "storage_primary_access_key" {
  value     = module.cdn_storage_account.primary_access_key
  sensitive = true
}

output "storage_primary_blob_connection_string" {
  value     = module.cdn_storage_account.primary_blob_connection_string
  sensitive = true
}

output "storage_primary_blob_host" {
  value = module.cdn_storage_account.primary_blob_host
}

output "storage_primary_web_host" {
  value = module.cdn_storage_account.primary_web_host
}

output "storage_name" {
  value = module.cdn_storage_account.name
}

output "storage_resource_group_name" {
  value = module.cdn_storage_account.resource_group_name
}
