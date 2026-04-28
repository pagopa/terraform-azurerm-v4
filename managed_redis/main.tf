resource "azurerm_managed_redis" "this" {
  name                = "${var.name}-redis"
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
    persistence_redis_database_backup_frequency   = try(var.persistence_configuration.rdb_enabled, null)
    persistence_append_only_file_backup_frequency = try(var.persistence_configuration.aof_enabled, null)
    geo_replication_group_name                    = var.geo_replication_group_name

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

  name                = "${var.name}-redis-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-private-service-connection"
    private_connection_resource_id = azurerm_managed_redis.this.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.name}-private-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

#
# Monitoring & Alerts Configuration
#

locals {
  # Map defining all possible alerts and linking them to input variables
  all_alerts = {
    cpu = {
      enabled      = var.cpu_alert_enabled
      display_name = "High CPU Usage"
      metric_name  = "cpu"
      aggregation  = "Average"
      operator     = "GreaterThan"
      threshold    = var.cpu_threshold
      severity     = 2
    }
    memory = {
      enabled      = var.memory_alert_enabled
      display_name = "High Memory Usage"
      metric_name  = "memoryusagepercent"
      aggregation  = "Average"
      operator     = "GreaterThan"
      threshold    = var.memory_threshold
      severity     = 2
    }
    eviction = {
      enabled      = var.eviction_alert_enabled
      display_name = "Eviction Events"
      metric_name  = "evictedkeys"
      aggregation  = "Total"
      operator     = "GreaterThan"
      threshold    = var.eviction_threshold
      severity     = 2
    }
    connection = {
      enabled      = var.connection_alert_enabled
      display_name = "High Connection Count"
      metric_name  = "connectedclients"
      aggregation  = "Maximum"
      operator     = "GreaterThan"
      threshold    = var.connection_threshold
      severity     = 3
    }
  }

  # Filter the map to include only alerts where 'enabled' is true
  active_alerts = { for k, v in local.all_alerts : k => v if v.enabled }
}

resource "azurerm_monitor_metric_alert" "alert" {
  # Loop only through active alerts if at least one action group is defined
  for_each = length(var.alert_action_group_ids) > 0 ? local.active_alerts : {}

  name                = "${azurerm_managed_redis.this.name} - ${each.value.display_name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_managed_redis.this.id]
  description         = "Automatic alert for ${lower(each.value.display_name)}"
  severity            = each.value.severity
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = true

  criteria {
    metric_namespace       = "Microsoft.Cache/managedredis"
    metric_name            = each.value.metric_name
    aggregation            = each.value.aggregation
    operator               = each.value.operator
    threshold              = each.value.threshold
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