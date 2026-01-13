output "default_key" {
  value     = module.main_slot.default_key
  sensitive = true
}

output "master_key" {
  value     = module.main_slot.master_key
  sensitive = true
}

output "primary_key" {
  value     = module.main_slot.primary_key
  sensitive = true
}

output "name" {
  value = module.main_slot.name
}

output "resource_group" {
  value = module.main_slot.resource_group_name
}

output "default_hostname" {
  value = module.main_slot.default_hostname
}

output "service_plan_name" {
  value = azurerm_app_service_plan.function_service_plan.name
}

output "service_plan_id" {
  value = azurerm_app_service_plan.function_service_plan.id
}