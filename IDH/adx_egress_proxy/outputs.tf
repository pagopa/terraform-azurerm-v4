output "vmss_snet" {
  value = module.vmss_snet
}

output "vmss_pls_snet" {
  value = module.vmss_pls_snet
}

output "load_balancer_name" {
  value = module.load_balancer_egress.azurerm_lb_name
}

output "load_balancer_id" {
  value = module.load_balancer_egress.azurerm_lb_id
}

output "load_balancer_rg" {
  value = module.load_balancer_egress.azurerm_lb_rg_name
}


output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.vmss_egress.id
}

output "vmss_rg" {
  value = azurerm_linux_virtual_machine_scale_set.vmss_egress.resource_group_name
}

output "vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.vmss_egress.name
}

output "vmss_scale_id" {
  value = one(azurerm_monitor_autoscale_setting.vmss_scale[*].id)
}

output "vmss_scale_name" {
  value = one(azurerm_monitor_autoscale_setting.vmss_scale[*].name)
}


output "vmss_scale_rg" {
  value = one(azurerm_monitor_autoscale_setting.vmss_scale[*].resource_group_name)
}

output "database_map" {
  value       = local.database_map
  description = "Map of database names to their corresponding connection strings and keys."
}

output "database_map_kv_secret_name" {
  value = one(azurerm_key_vault_secret.output_database_map[*].name)
}
