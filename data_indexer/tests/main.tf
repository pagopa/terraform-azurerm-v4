resource "azurerm_resource_group" "rg" {
  name     = "${local.project}-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.project}-vnet"
  address_space       = var.vnet_address_space
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = var.tags
}

resource "azurerm_private_dns_zone" "privatelink_servicebus" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "privatelink_blob_core" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "privatelink_queue_core" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "privatelink_table_core" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "servicebus_private_vnet" {
  name                  = azurerm_virtual_network.vnet.name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_servicebus.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_core_private_vnet" {
  name                  = azurerm_virtual_network.vnet.name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_blob_core.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "queue_core_private_vnet" {
  name                  = azurerm_virtual_network.vnet.name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_queue_core.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "table_core_private_vnet" {
  name                  = azurerm_virtual_network.vnet.name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_table_core.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}

module "pendpoints_snet" {
  source                            = "../../subnet"
  name                              = format("%s-pendpoints-snet", local.project)
  address_prefixes                  = var.cidr_subnet_pendpoints
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  service_endpoints                 = ["Microsoft.EventHub"]
  private_endpoint_network_policies = "Disabled"
}

module "event_hub" {
  source                     = "../../eventhub"
  name                       = format("%s-evh-ns", local.project)
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  sku                        = "Basic"
  virtual_network_ids        = [azurerm_virtual_network.vnet.id]
  private_endpoint_subnet_id = module.pendpoints_snet.id
  private_endpoint_created   = true
  private_dns_zones = {
    id                  = [azurerm_private_dns_zone.privatelink_servicebus.id]
    name                = [azurerm_private_dns_zone.privatelink_servicebus.name]
    resource_group_name = azurerm_resource_group.rg.name
  }

  eventhubs = [
    {
      name              = "test"
      partitions        = 5
      message_retention = 1
      consumers         = []
      keys = [
        {
          name   = "sender"
          listen = false
          send   = true
          manage = false
        },
        {
          name   = "receiver"
          listen = true
          send   = false
          manage = false
        }
      ]
    }
  ]

  public_network_access_enabled = true
  network_rulesets              = []

  alerts_enabled = false
  action         = []

  tags = var.tags
}

module "data_indexer" {
  source = "../../data_indexer"

  location = var.location
  name     = format("%s-test", local.project)
  virtual_network = {
    name                = azurerm_virtual_network.vnet.name
    resource_group_name = azurerm_resource_group.rg.name
  }
  config = {
    json_config_path = "./config.json"
  }
  subnet = {
    address_prefixes = ["10.0.2.0/26"]
  }
  internal_storage = {
    private_dns_zone_blob_ids  = [azurerm_private_dns_zone.privatelink_blob_core.id]
    private_dns_zone_queue_ids = [azurerm_private_dns_zone.privatelink_queue_core.id]
    private_dns_zone_table_ids = [azurerm_private_dns_zone.privatelink_table_core.id]
    private_endpoint_subnet_id = module.pendpoints_snet.id
  }
  evh_config = {
    hub_ids = module.event_hub.hub_ids
    topics  = ["test"]
  }
  tags = var.tags
}
