output "id" {
  value = module.storage_account.id
}

output "resource_group_name" {
  value = module.storage_account.resource_group_name
}

output "primary_connection_string" {
  value     = module.storage_account.primary_connection_string
  sensitive = true
}

output "primary_access_key" {
  value     = module.storage_account.primary_access_key
  sensitive = true
}

output "primary_blob_connection_string" {
  value     = module.storage_account.primary_blob_connection_string
  sensitive = true
}

output "primary_blob_host" {
  value = module.storage_account.primary_blob_host
}

output "primary_web_host" {
  value = module.storage_account.primary_web_host
}

output "name" {
  value = module.storage_account.name
}

output "primary_blob_endpoint" {
  value = module.storage_account.primary_blob_endpoint
}

output "identity" {
  value = var.enable_identity != null ? module.storage_account.identity : null
}
