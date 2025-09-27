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
