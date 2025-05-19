output "id" {
  value = module.pgflex.id
}

output "name" {
  value = module.pgflex.name
}

output "fqdn" {
  value = module.pgflex.fqdn
}

output "public_access_enabled" {
  value = module.pgflex.public_access_enabled
}

output "administrator_login" {
  value = var.administrator_login
}

output "administrator_password" {
  value     = var.administrator_password
  sensitive = true
}

output "connection_port" {
  value     = module.idh_loader.idh_config.server_parameters.pgbouncer_enabled ? "6432" : "5432"
  sensitive = false
}


output "replica_id" {
  value = module.replica.*.id
}

output "replica_name" {
  value = module.replica.*.name
}

output "replica_fqdn" {
  value = module.replica.*.fqdn
}

output "virtual_endpoint_name" {
  value = azurerm_postgresql_flexible_server_virtual_endpoint.virtual_endpoint.*.name
}
