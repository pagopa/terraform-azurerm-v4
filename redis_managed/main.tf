#
# Managed Redis Instance
#
resource "azurerm_managed_redis" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  tags = var.tags
}

#
# Private Endpoint for secure connectivity
#
resource "azurerm_private_endpoint" "redis" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = var.private_endpoint_name != null ? var.private_endpoint_name : "${var.name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    is_manual_connection           = var.private_endpoint_approval_required
    private_connection_resource_id = azurerm_managed_redis.this.id
    subresource_names              = ["redisCache"]
  }

  tags = var.tags
}

#
# Action Group for alerts
#
resource "azurerm_monitor_action_group" "redis_alerts" {
  count               = var.action_group_enabled ? 1 : 0
  name                = var.action_group_name != null ? var.action_group_name : "${var.name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr("${var.name}-ag", 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name                    = "email-${replace(replace(replace(email_receiver.value, "@", "-"), ".", "-"), "+", "-")}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = var.tags
}



#
# Alert: High CPU Usage
#
resource "azurerm_monitor_metric_alert" "redis_high_cpu" {
  count               = var.action_group_enabled ? 1 : 0
  name                = "${var.name}-high-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when Managed Redis CPU exceeds ${var.alert_high_cpu_threshold}%"
  enabled             = true

  criteria {
    metric_name      = "CPU"
    metric_namespace = "Microsoft.Cache/redis"
    operator         = "GreaterThan"
    threshold        = var.alert_high_cpu_threshold
    aggregation      = "Average"
  }

  window_size          = "PT5M"
  frequency            = "PT1M"
  severity             = 2
  action {
    action_group_id = azurerm_monitor_action_group.redis_alerts[0].id
  }

  tags = var.tags
}

#
# Alert: High Memory Usage
#
resource "azurerm_monitor_metric_alert" "redis_high_memory" {
  count               = var.action_group_enabled ? 1 : 0
  name                = "${var.name}-high-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when Managed Redis memory exceeds ${var.alert_high_memory_threshold}%"
  enabled             = true

  criteria {
    metric_name      = "UsedMemoryPercentage"
    metric_namespace = "Microsoft.Cache/redis"
    operator         = "GreaterThan"
    threshold        = var.alert_high_memory_threshold
    aggregation      = "Average"
  }

  window_size          = "PT5M"
  frequency            = "PT1M"
  severity             = 2
  action {
    action_group_id = azurerm_monitor_action_group.redis_alerts[0].id
  }

  tags = var.tags
}

#
# Alert: High Eviction Rate
#
resource "azurerm_monitor_metric_alert" "redis_high_evictions" {
  count               = var.action_group_enabled ? 1 : 0
  name                = "${var.name}-high-evictions-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when Managed Redis evictions exceed ${var.alert_eviction_threshold} per minute"
  enabled             = true

  criteria {
    metric_name      = "EvictedKeys"
    metric_namespace = "Microsoft.Cache/redis"
    operator         = "GreaterThan"
    threshold        = var.alert_eviction_threshold
    aggregation      = "Total"
  }

  window_size          = "PT1M"
  frequency            = "PT1M"
  severity             = 3
  action {
    action_group_id = azurerm_monitor_action_group.redis_alerts[0].id
  }

  tags = var.tags
}

#
# Alert: Connection Failures
#
resource "azurerm_monitor_metric_alert" "redis_connection_failures" {
  count               = var.action_group_enabled ? 1 : 0
  name                = "${var.name}-connection-failures-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Alert when Managed Redis connection failures detected"
  enabled             = true

  criteria {
    metric_name      = "ConnectedClients"
    metric_namespace = "Microsoft.Cache/redis"
    operator         = "LessThan"
    threshold        = 1
    aggregation      = "Minimum"
  }

  window_size          = "PT5M"
  frequency            = "PT1M"
  severity             = 1
  action {
    action_group_id = azurerm_monitor_action_group.redis_alerts[0].id
  }

  tags = var.tags
}
