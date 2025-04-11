locals {
  consumers = { for hc in flatten([for h in var.eventhubs :
    [for c in h.consumers : {
      hub  = h.name
      name = c
  }]]) : "${hc.hub}.${hc.name}" => hc }

  keys = { for hk in flatten([for h in var.eventhubs :
    [for k in h.keys : {
      hub = h.name
      key = k
  }]]) : "${hk.hub}.${hk.key.name}" => hk }

  hubs = { for h in var.eventhubs : h.name => h }
}

data "azurerm_eventhub_namespace" "evh_namespace" {
  name                = var.event_hub_namespace_name
  resource_group_name = var.event_hub_namespace_resource_group_name
}

#
# Eventhub configuration
#
resource "azurerm_eventhub" "events" {
  for_each = local.hubs

  name              = each.key
  namespace_id      = data.azurerm_eventhub_namespace.evh_namespace.id
  partition_count   = each.value.partitions
  message_retention = each.value.message_retention
}

#
# Consumer groups
#
resource "azurerm_eventhub_consumer_group" "events" {
  for_each = local.consumers

  name                = each.value.name
  namespace_name      = data.azurerm_eventhub_namespace.evh_namespace.name
  resource_group_name = data.azurerm_eventhub_namespace.evh_namespace.resource_group_name

  eventhub_name = each.value.hub

  user_metadata = "terraform"

  depends_on = [azurerm_eventhub.events]
}

#
# Authorization rules
#
resource "azurerm_eventhub_authorization_rule" "events" {
  for_each = local.keys

  name                = each.value.key.name
  namespace_name      = data.azurerm_eventhub_namespace.evh_namespace.name
  resource_group_name = data.azurerm_eventhub_namespace.evh_namespace.resource_group_name

  eventhub_name = each.value.hub

  listen = each.value.key.listen
  send   = each.value.key.send
  manage = each.value.key.manage

  depends_on = [azurerm_eventhub.events]
}
