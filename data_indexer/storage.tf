
module "internal_storage_account" {
  source = "../storage_account"

  name                          = "${replace(var.name, "-", "")}dist"
  account_kind                  = var.internal_storage.account_kind
  account_tier                  = var.internal_storage.account_tier
  account_replication_type      = var.internal_storage.account_replication_type
  access_tier                   = var.internal_storage.access_tier
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  advanced_threat_protection    = false
  public_network_access_enabled = false

  tags = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  name                = "${module.internal_storage_account.name}-blob-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = var.internal_storage.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${module.internal_storage_account.name}-blob"
    private_connection_resource_id = module.internal_storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = var.internal_storage.private_dns_zone_blob_ids
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "queue" {
  name                = "${module.internal_storage_account.name}-queue-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = var.internal_storage.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${module.internal_storage_account.name}-queue"
    private_connection_resource_id = module.internal_storage_account.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = var.internal_storage.private_dns_zone_queue_ids
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "table" {
  name                = "${module.internal_storage_account.name}-table-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = var.internal_storage.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${module.internal_storage_account.name}-table"
    private_connection_resource_id = module.internal_storage_account.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = var.internal_storage.private_dns_zone_table_ids
  }

  tags = var.tags
}
