output "idh_category" {
  value = var.idh_category
}

output "idh_resource" {
  value = var.idh_resource
}

output "idh_config" {
  value = local.local_data[var.idh_category][var.idh_resource]
}
