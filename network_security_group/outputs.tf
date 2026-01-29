output "nsg_custom_details" {
  description = "Detailed map of created NSGs including names and resource groups"
  value = { for k, nsg in azurerm_network_security_group.custom_nsg : k => {
    name                = nsg.name
    resource_group_name = nsg.resource_group_name
    id                  = nsg.id
  } }
}