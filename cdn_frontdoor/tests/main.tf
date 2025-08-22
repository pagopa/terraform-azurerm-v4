locals {
  dns_zone_name = "${var.prefix}.pagopa.it"
  hostname      = "www.${var.prefix}.pagopa.it"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${local.project}-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${local.project}-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = "30"
  daily_quota_gb      = -1

  tags = var.tags
}

resource "azurerm_key_vault" "this" {
  name                = local.project
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  tags = var.tags
}

resource "azurerm_dns_zone" "zone" {
  name                = local.dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}

#
# CDN
#
module "cdn" {
  source = "../../cdn_frontdoor"

  location                     = var.location
  dns_zone_name                = local.dns_zone_name
  dns_zone_resource_group_name = azurerm_resource_group.rg.name
  storage_account_error_404_document           = "error_404.html"
  hostname                     = local.hostname
  storage_account_index_document               = "index.html"
  keyvault_resource_group_name = azurerm_resource_group.rg.name
  keyvault_subscription_id     = data.azurerm_client_config.current.subscription_id
  keyvault_vault_name          = azurerm_key_vault.this.name
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.log_analytics_workspace.id
  dns_prefix_name              = local.project
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = var.tags
}

module "cdn_different_location" {
  source = "../../cdn_frontdoor"

  location                     = var.location
  cdn_location                 = var.location_cdn
  dns_zone_name                = local.dns_zone_name
  dns_zone_resource_group_name = azurerm_resource_group.rg.name
  storage_account_error_404_document           = "error_404.html"
  hostname                     = local.hostname
  storage_account_index_document               = "index.html"
  keyvault_resource_group_name = azurerm_resource_group.rg.name
  keyvault_subscription_id     = data.azurerm_client_config.current.subscription_id
  keyvault_vault_name          = azurerm_key_vault.this.name
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.log_analytics_workspace.id
  dns_prefix_name              = local.project
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = var.tags
}





