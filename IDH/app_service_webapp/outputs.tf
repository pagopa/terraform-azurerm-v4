output "id" {
  value       = module.main_slot.id
  description = "The ID of the main App Service slot."
}

output "name" {
  value       = module.main_slot.name
  description = "The name of the main App Service slot."
}

output "default_site_hostname" {
  value       = module.main_slot.default_site_hostname
  description = "The default site hostname of the main App Service slot."
}

output "principal_id" {
  value       = module.main_slot.principal_id
  description = "The principal ID of the system-assigned identity for the main App Service slot."
}

output "staging_id" {
  value       = try(module.staging_slot[0].id, null)
  description = "The ID of the staging App Service slot."
}

output "staging_name" {
  value       = try(module.staging_slot[0].name, null)
  description = "The name of the staging App Service slot."
}

output "staging_default_site_hostname" {
  value       = try(module.staging_slot[0].default_site_hostname, null)
  description = "The default site hostname of the staging App Service slot."
}

output "staging_principal_id" {
  value       = try(module.staging_slot[0].principal_id, null)
  description = "The principal ID of the system-assigned identity for the staging App Service slot."
}

output "plan_id" {
  value       = module.main_slot.plan_id
  description = "The ID of the App Service Plan."
}

output "custom_domain_verification_id" {
  value       = module.main_slot.custom_domain_verification_id
  description = "The custom domain verification ID of the main App Service slot."
}

output "plan_name" {
  value       = module.main_slot.plan_name
  description = "The name of the App Service Plan."
}

output "private_endpoint_main_slot" {
  value       = try(azurerm_private_endpoint.main_slot_private_endpoint[0], null)
  description = "The private endpoint resource of the main App Service slot."
}

output "private_endpoint_staging_slot" {
  value       = try(azurerm_private_endpoint.staging_slot_private_endpoint[0], null)
  description = "The private endpoint resource of the staging App Service slot."
}

output "private_endpoint_snet_id" {
  value       = try(module.private_endpoint_snet[0].id, null)
  description = "The ID of the subnet used for the private endpoint."
}

output "egress_snet_id" {
  value       = try(module.egress_snet[0].id, null)
  description = "The ID of the subnet used for egress traffic."
}

output "autoscale_settings_id" {
  value       = try(azurerm_monitor_autoscale_setting.autoscale_settings[0].id, null)
  description = "The ID of the autoscale settings."
}

output "idh_resource_configuration" {
  value       = module.idh_loader.idh_resource_configuration
  description = "The IDH resource configuration object."
}
