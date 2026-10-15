data "azurerm_nat_gateway" "nat_gateway" {
  count               = var.nat_gateway != null ? 1 : 0
  name                = var.nat_gateway.name
  resource_group_name = var.nat_gateway.resource_group_name
}


data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet.name
  resource_group_name = var.vnet.resource_group_name
}

data "azurerm_key_vault" "output_kv" {
  count               = var.output_kv != null ? 1 : 0
  name                = var.output_kv.name
  resource_group_name = var.output_kv.resource_group_name
}


data "azurerm_client_config" "current" {}
