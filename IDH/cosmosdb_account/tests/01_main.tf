resource "azurerm_resource_group" "cosmos_idh_test_rg" {
  location = var.location
  name     = "test-resource-group-cosmos-db-idh-${random_string.test.result}"
}

module "cosmos_idh_test" {
  source                     = "./.."
  prefix                     = "pagopa"
  domain                     = "test"
  resource_group_name        = azurerm_resource_group.cosmos_idh_test_rg.name
  env                        = var.env
  idh_resource               = "cosmos_mongo6"
  location                   = var.location
  name                       = "test-idh-${var.env}-${random_string.test.result}"
  main_geo_location_location = var.location
  tags                       = {}
}
