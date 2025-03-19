output "risorse" {
  value = data.azurerm_resources.sub_resources
}
output "localrisorse" {
  value = local.allowed_resource_type
}