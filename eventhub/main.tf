resource "null_resource" "basic_sku_dont_support_private_endpoint" {
  count = (var.sku == "Basic" && var.private_endpoint_created) ? "ERROR: Private endpoint are not supported into sku Basic" : 0
}

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

#
# Eventhub namespace
# ℹ️ zone redundant is default for sku Standard and Premium
#
resource "azurerm_eventhub_namespace" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.capacity
  auto_inflate_enabled          = var.auto_inflate_enabled
  maximum_throughput_units      = var.auto_inflate_enabled ? var.maximum_throughput_units : null
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version

  dynamic "network_rulesets" {
    for_each = var.network_rulesets
    content {
      default_action                = network_rulesets.value["default_action"]
      public_network_access_enabled = network_rulesets.value["public_network_access_enabled"]
      # virtual_network_rule {} # optional one ore more
      dynamic "virtual_network_rule" {
        for_each = network_rulesets.value["virtual_network_rule"]
        content {
          subnet_id                                       = virtual_network_rule.value["subnet_id"]
          ignore_missing_virtual_network_service_endpoint = virtual_network_rule.value["ignore_missing_virtual_network_service_endpoint"]
        }
      }
      dynamic "ip_rule" {
        for_each = network_rulesets.value["ip_rule"]
        content {
          ip_mask = ip_rule.value["ip_mask"]
          action  = ip_rule.value["action"]
        }
      }
      trusted_service_access_enabled = network_rulesets.value["trusted_service_access_enabled"]
    }
  }

  tags = var.tags
}

#
# Eventhub configuration
#
resource "azurerm_eventhub" "events" {
  for_each = local.hubs

  name              = each.key
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = each.value.partitions
  message_retention = each.value.message_retention

  lifecycle {
    ignore_changes = [
      retention_description
    ]
  }

}

resource "azurerm_eventhub_consumer_group" "events" {
  for_each = local.consumers

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = each.value.hub
  resource_group_name = var.resource_group_name
  user_metadata       = "terraform"

  depends_on = [azurerm_eventhub.events]
}

resource "azurerm_eventhub_authorization_rule" "events" {
  for_each = local.keys

  name                = each.value.key.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = each.value.hub
  resource_group_name = var.resource_group_name

  listen = each.value.key.listen
  send   = each.value.key.send
  manage = each.value.key.manage

  depends_on = [azurerm_eventhub.events]
}

#
# 🌐 Network
#

resource "azurerm_private_endpoint" "eventhub" {
  count = var.private_endpoint_created ? 1 : 0

  name                = "${var.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.private_endpoint_resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_dns_zone_group {
    name                 = "${var.name}-private-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zones_ids
  }

  private_service_connection {
    name                           = "${var.name}-private-service-connection"
    private_connection_resource_id = azurerm_eventhub_namespace.this.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }
  tags = var.tags
}


#
# Alert
#

resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts_create ? var.metric_alerts : {}

  name                = format("%s-%s", azurerm_eventhub_namespace.this.name, upper(each.key))
  description         = each.value.description
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_eventhub_namespace.this.id]
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  enabled             = var.alerts_enabled

  dynamic "action" {
    for_each = var.action
    content {
      # action_group_id - (required) is a type of string
      action_group_id = action.value["action_group_id"]
      # webhook_properties - (optional) is a type of map of string
      webhook_properties = action.value["webhook_properties"]
    }
  }

  criteria {
    aggregation      = each.value.aggregation
    metric_namespace = "microsoft.eventhub/namespaces"
    metric_name      = each.value.metric_name
    operator         = each.value.operator
    threshold        = each.value.threshold

    dynamic "dimension" {
      for_each = each.value.dimension
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }
  tags = var.tags
}
