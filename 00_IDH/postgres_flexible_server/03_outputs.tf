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
  value     = local.local_data[var.idh_resource].pgbouncer_enabled ? "6432" : "5432"
  sensitive = false
}
