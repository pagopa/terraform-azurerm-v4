#tfsec:ignore:azure-storage-queue-services-logging-enabled
resource "azurerm_storage_account" "this" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_kind                     = var.account_kind
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  access_tier                      = var.access_tier
  https_traffic_only_enabled       = true
  min_tls_version                  = var.min_tls_version
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  is_hns_enabled                   = var.is_hns_enabled
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  public_network_access_enabled    = var.public_network_access_enabled
  sftp_enabled                     = var.is_sftp_enabled

  dynamic "blob_properties" {
    for_each = ((var.account_kind == "BlockBlobStorage" || var.account_kind == "StorageV2") ? [1] : [])
    content {
      versioning_enabled            = var.blob_versioning_enabled
      change_feed_enabled           = var.blob_change_feed_enabled
      change_feed_retention_in_days = var.blob_change_feed_retention_in_days
      last_access_time_enabled      = var.blob_last_access_time_enabled

      dynamic "delete_retention_policy" {
        for_each = (var.blob_delete_retention_days == 0 ? [] : [1])
        content {
          days = var.blob_delete_retention_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = (var.blob_container_delete_retention_days == 0 ? [] : [1])
        content {
          days = var.blob_container_delete_retention_days
        }
      }

      dynamic "restore_policy" {
        for_each = (var.blob_storage_policy.blob_restore_policy_days == 0 ? [] : [1])
        content {
          days = var.blob_storage_policy.blob_restore_policy_days
        }
      }

      dynamic "cors_rule" {
        for_each = var.blob_cors_rule != null ? [1] : []
        content {
          allowed_headers    = var.blob_cors_rule.allowed_headers
          allowed_methods    = var.blob_cors_rule.allowed_methods
          allowed_origins    = var.blob_cors_rule.allowed_origins
          exposed_headers    = var.blob_cors_rule.exposed_headers
          max_age_in_seconds = var.blob_cors_rule.max_age_in_seconds
        }
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]

    content {
      default_action             = length(network_rules.value.ip_rules) == 0 && length(network_rules.value.virtual_network_subnet_ids) == 0 ? network_rules.value.default_action : "Deny"
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  dynamic "static_website" {
    for_each = var.index_document != null && var.error_404_document != null ? ["dummy"] : []

    content {
      index_document     = var.index_document
      error_404_document = var.error_404_document
    }
  }

  dynamic "custom_domain" {
    for_each = var.custom_domain.name != null ? ["dummy"] : []

    content {
      name          = var.custom_domain.name
      use_subdomain = var.custom_domain.use_subdomain
    }
  }

  dynamic "identity" {
    for_each = (var.enable_identity ? [1] : [])
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "immutability_policy" {
    for_each = var.blob_storage_policy.enable_immutability_policy ? [1] : []

    content {
      allow_protected_append_writes = var.immutability_policy_props.allow_protected_append_writes
      state                         = "Unlocked"
      period_since_creation_in_days = var.immutability_policy_props.period_since_creation_in_days
    }
  }

  # the use of storage_account_customer_managed_key resource will cause a bug on the plan: this paramenter will always see as changed.
  # the state property is ignored because is overridden from a null_resource.
  lifecycle {
    ignore_changes = [
      customer_managed_key,
      immutability_policy.0.state
    ]
  }

  tags = var.tags
}


# Private endpoints

resource "azurerm_private_endpoint" "blob" {
  count = var.private_endpoint_enabled && length(var.private_dns_zone_blob_ids) > 0 ? 1 : 0

  name                = "${var.name}-private-endpoint-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-private-endpoint-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_blob_ids != null ? ["dummy"] : []
    content {
      name                 = "private-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_blob_ids
    }
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "table" {
  count = var.private_endpoint_enabled && length(var.private_dns_zone_table_ids) > 0 ? 1 : 0

  name                = "${var.name}-private-endpoint-table"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-private-endpoint-table"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_table_ids != null ? ["dummy"] : []
    content {
      name                 = "private-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_table_ids
    }
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "queue" {
  count = var.private_endpoint_enabled && length(var.private_dns_zone_queue_ids) > 0 ? 1 : 0

  name                = "${var.name}-private-endpoint-queue"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-private-endpoint-queue"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_queue_ids != null ? ["dummy"] : []
    content {
      name                 = "private-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_queue_ids
    }
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "file" {
  count = var.private_endpoint_enabled && length(var.private_dns_zone_file_ids) > 0 ? 1 : 0

  name                = "${var.name}-private-endpoint-file"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-private-endpoint-file"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_file_ids != null ? ["dummy"] : []
    content {
      name                 = "private-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_file_ids
    }
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "web" {
  count = var.private_endpoint_enabled && length(var.private_dns_zone_web_ids) > 0 ? 1 : 0

  name                = "${var.name}-private-endpoint-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-private-endpoint-web"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["web"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_web_ids != null ? ["dummy"] : []
    content {
      name                 = "private-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_web_ids
    }
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "dfs" {
  count = var.private_endpoint_enabled && length(var.private_dns_zone_dfs_ids) > 0 ? 1 : 0

  name                = "${var.name}-private-endpoint-dfs"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-private-endpoint-dfs"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_dfs_ids != null ? ["dummy"] : []
    content {
      name                 = "private-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_dfs_ids
    }
  }
  tags = var.tags
}

# Enable advanced threat protection
resource "azurerm_advanced_threat_protection" "this" {
  count = var.advanced_threat_protection == true && var.use_legacy_defender_version == true ? 1 : 0

  target_resource_id = azurerm_storage_account.this.id
  enabled            = true
}

resource "azurerm_security_center_storage_defender" "this" {
  count = var.advanced_threat_protection == true && var.use_legacy_defender_version == false ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id
}

# -----------------------------------------------
# Alerts
# -----------------------------------------------

resource "azurerm_monitor_metric_alert" "storage_account_low_availability" {
  count = var.enable_low_availability_alert ? 1 : 0

  name                = "[${var.domain != null ? "${var.domain} | " : ""}${azurerm_storage_account.this.name}] Low Availability"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_storage_account.this.id]
  description         = "The average availability is less than 99.8%. Runbook: not needed."
  severity            = 0
  window_size         = "PT5M"
  frequency           = "PT5M"
  auto_mitigate       = false

  # Metric info
  # https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-supported#microsoftstoragestorageaccounts
  criteria {
    metric_namespace       = "Microsoft.Storage/storageAccounts"
    metric_name            = "Availability"
    aggregation            = "Average"
    operator               = "LessThan"
    threshold              = var.low_availability_threshold
    skip_metric_validation = false
  }

  dynamic "action" {
    for_each = var.action
    content {
      action_group_id    = action.value["action_group_id"]
      webhook_properties = action.value["webhook_properties"]
    }
  }

  tags = var.tags
}

resource "null_resource" "immutability" {

  count = var.blob_storage_policy.enable_immutability_policy ? 1 : 0

  triggers = {
    immutability_policy : var.blob_storage_policy.enable_immutability_policy
    resouce_group_name : var.resource_group_name
    name : var.name
  }

  provisioner "local-exec" {
    command = <<EOT
      if ${self.triggers.immutability_policy}; then
        az storage account update --immutability-state Locked \
          --resource-group ${self.triggers.resouce_group_name} \
          --name ${self.triggers.name} \
          --query "id"
        # query is used to hide other properties from logging
      fi
    EOT
  }

  depends_on = [
    azurerm_storage_account.this
  ]
}
