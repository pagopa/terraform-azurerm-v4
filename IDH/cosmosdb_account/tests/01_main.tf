resource "azurerm_resource_group" "cosmos_idh_test_rg" {
  location = var.location
  name     = "test-resource-group-cosmos-db-idh-${random_string.test.result}"
}

module "cosmos_idh_test" {
  for_each                   = toset(var.env)
  source                     = "./.."
  product_name               = "pagopa"
  domain                     = "test"
  resource_group_name        = azurerm_resource_group.cosmos_idh_test_rg.name
  env                        = each.value
  idh_resource_tier               = "cosmos_mongo6"
  location                   = var.location
  name                       = "test-idh-${each.value}-${random_string.test.result}"
  main_geo_location_location = var.location
  additional_geo_locations = each.value == "prod" ? [{
    location          = "australiaeast"
    failover_priority = 2
    zone_redundant    = true
  }] : []
  tags = {}
}
