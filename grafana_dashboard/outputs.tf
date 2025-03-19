output "risorse" {
  value = jsonencode(data.azurerm_resources.sub_resources.required_tags)
}
output "localrisorse" {
  value = local.allowed_resource_type
}