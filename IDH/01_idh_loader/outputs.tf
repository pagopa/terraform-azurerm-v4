output "idh_resource_type" {
  value = var.idh_resource_type
}

output "idh_resource_tier" {
  value = var.idh_resource_tier
}

output "idh_resource_configuration" {
  value = local.tiers_configurations[var.idh_resource_tier]
}

output "idh_tiers_configurations" {
  value = local.tiers_configurations
}

output "non_paired_locations" {
  value = [
    "italynorth",
    "spaincentral"
  ]
}
