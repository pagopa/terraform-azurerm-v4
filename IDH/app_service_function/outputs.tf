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

output "default_hostname" {
  value = module.main_slot.default_hostname
}

output "service_plan_name" {
  value = azurerm_app_service_plan.function_service_plan.name
}

output "service_plan_id" {
  value = azurerm_app_service_plan.function_service_plan.id
}