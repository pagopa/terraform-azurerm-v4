output "idh_category" {
  value = var.idh_resource_type
}

output "idh_resource" {
  value = var.idh_resource_tier
}

output "idh_config" {
  value = local.local_data[var.idh_resource_tier]
}
