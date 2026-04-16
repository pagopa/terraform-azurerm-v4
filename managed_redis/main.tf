resource "azurerm_managed_redis" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name                  = var.sku_name
  high_availability_enabled = var.high_availability_enabled
  public_network_access     = var.public_network_access

  tags = var.tags

  default_database {
    client_protocol                               = var.client_protocol
    clustering_policy                             = var.clustering_policy
    eviction_policy                               = var.eviction_policy
    access_keys_authentication_enabled            = var.access_keys_authentication_enabled
    persistence_redis_database_backup_frequency   = var.persistence_configuration.rdb_enabled ? "1h" : null
    persistence_append_only_file_backup_frequency = var.persistence_configuration.aof_enabled ? "1s" : null

    dynamic "module" {
      for_each = var.modules
      content {
        name = module.value.name
      }
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_config != null ? [var.customer_managed_key_config] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }
}

#
# Private Endpoint
#

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "${var.name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_managed_redis.this.id
    subresource_names              = ["default"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = var.tags
}

#
# Alerts
#

resource "azurerm_monitor_metric_alert" "cpu_usage" {
  count = var.enable_cpu_alerts && length(var.alert_action_group_ids) > 0 ? 1 : 0

  name                = "${azurerm_managed_redis.this.name} - High CPU Usage"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when CPU usage exceeds ${var.cpu_usage_percentage_threshold}%"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = false

  criteria {
    metric_namespace       = "Microsoft.Cache/managedredis"
    metric_name            = "cpu"
    aggregation            = "Average"
    operator               = "GreaterThan"
    threshold              = var.cpu_usage_percentage_threshold
    skip_metric_validation = false
  }

  dynamic "action" {
    for_each = var.alert_action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "memory_usage" {
  count = var.enable_memory_alerts && length(var.alert_action_group_ids) > 0 ? 1 : 0

  name                = "${azurerm_managed_redis.this.name} - High Memory Usage"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when memory usage exceeds ${var.memory_usage_percentage_threshold}%"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = false

  criteria {
    metric_namespace       = "Microsoft.Cache/managedredis"
    metric_name            = "memoryusagepercent"
    aggregation            = "Average"
    operator               = "GreaterThan"
    threshold              = var.memory_usage_percentage_threshold
    skip_metric_validation = false
  }

  dynamic "action" {
    for_each = var.alert_action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "eviction_events" {
  count = var.enable_eviction_alerts && length(var.alert_action_group_ids) > 0 ? 1 : 0

  name                = "${azurerm_managed_redis.this.name} - Eviction Events Detected"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when eviction events occur"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = false

  criteria {
    metric_namespace       = "Microsoft.Cache/managedredis"
    metric_name            = "evictedkeys"
    aggregation            = "Total"
    operator               = "GreaterThan"
    threshold              = 0
    skip_metric_validation = false
  }

  dynamic "action" {
    for_each = var.alert_action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "connection_count" {
  count = var.enable_connection_alerts && length(var.alert_action_group_ids) > 0 ? 1 : 0

  name                = "${azurerm_managed_redis.this.name} - High Connection Count"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when connection count exceeds ${var.connection_count_threshold}"
  severity            = 3
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = false

  criteria {
    metric_namespace       = "Microsoft.Cache/managedredis"
    metric_name            = "connectedclients"
    aggregation            = "Maximum"
    operator               = "GreaterThan"
    threshold              = var.connection_count_threshold
    skip_metric_validation = false
  }

  dynamic "action" {
    for_each = var.alert_action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}
