data "azurerm_nat_gateway" "nat_gateway" {
  count = var.nat_gateway != null ? 1 : 0
  name                = var.nat_gateway.name
  resource_group_name = var.nat_gateway.resource_group_name
}


data "azurerm_resource_group" "vmss_rg" {
  name = var.vmss_resource_group_name
}
