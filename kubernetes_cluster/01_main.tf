# https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable
resource "null_resource" "b_series_not_ephemeral_system_check" {
  count = length(regexall("Standard_B", var.system_node_pool_vm_size)) > 0 && var.system_node_pool_os_disk_type == "Ephemeral" ? "ERROR: Burstable(B) series don't allow Ephemeral disks" : 0
}

resource "null_resource" "b_series_not_ephemeral_user_check" {
  count = length(regexall("Standard_B", var.user_node_pool_vm_size)) > 0 && var.user_node_pool_os_disk_type == "Ephemeral" && var.user_node_pool_enabled ? "ERROR: Burstable(B) series don't allow Ephemeral disks" : 0
}

resource "null_resource" "workload_identity_oidc_issuer_enabled_check" {
  count = var.workload_identity_enabled == true && var.oidc_issuer_enabled == false ? "OIDC Issuer must be enabled, in order to use Workload identity" : 0
}

locals {
  # for workload identity is mandatory to hava a oidc issuer enabled
  oidc_issuer_enabled = var.workload_identity_enabled ? true : var.oidc_issuer_enabled
}

#tfsec:ignore:AZU008
#tfsec:ignore:azure-container-logging addon_profile is deprecated, false positive
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled = var.private_cluster_enabled

  #
  # System node pool
  #
  default_node_pool {
    name = var.system_node_pool_name

    ### vm configuration
    vm_size = var.system_node_pool_vm_size
    # https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general
    os_disk_type                 = var.system_node_pool_os_disk_type # Managed or Ephemeral
    os_disk_size_gb              = var.system_node_pool_os_disk_size_gb
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = var.system_node_pool_only_critical_addons_enabled
    zones                        = var.system_node_pool_availability_zones
    ultra_ssd_enabled            = var.system_node_pool_ultra_ssd_enabled
    host_encryption_enabled      = var.system_node_pool_enable_host_encryption

    ### autoscaling
    auto_scaling_enabled = true
    node_count           = var.system_node_pool_node_count_min
    min_count            = var.system_node_pool_node_count_min
    max_count            = var.system_node_pool_node_count_max

    ### K8s node configuration
    max_pods    = var.system_node_pool_max_pods
    node_labels = var.system_node_pool_node_labels

    ### networking
    vnet_subnet_id         = var.vnet_subnet_id
    node_public_ip_enabled = false

    temporary_name_for_rotation = "tmp${var.system_node_pool_name}"

    upgrade_settings {
      max_surge                = var.upgrade_settings_max_surge
      drain_timeout_in_minutes = var.system_node_pool_upgrade_settings_drain_timeout_in_minutes
    }

    tags = merge(var.tags, var.system_node_pool_tags)
  }

  automatic_upgrade_channel = var.automatic_channel_upgrade
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_windows_node_os.enabled ? [1] : []
    content {
      day_of_month = var.maintenance_windows_node_os.day_of_month
      day_of_week  = var.maintenance_windows_node_os.day_of_week
      duration     = var.maintenance_windows_node_os.duration
      frequency    = var.maintenance_windows_node_os.frequency
      interval     = var.maintenance_windows_node_os.interval
      start_date   = var.maintenance_windows_node_os.start_date
      start_time   = var.maintenance_windows_node_os.start_time
      utc_offset   = var.maintenance_windows_node_os.utc_offset
      week_index   = var.maintenance_windows_node_os.week_index
    }
  }

  upgrade_override {
    force_upgrade_enabled = var.force_upgrade_enabled
    effective_until       = timeadd(timestamp(), "336h")
  }

  # managed identity type: https://docs.microsoft.com/en-us/azure/aks/use-managed-identity
  identity {
    type = "SystemAssigned"
  }

  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = local.oidc_issuer_enabled
  cost_analysis_enabled     = var.cost_analysis_enabled

  dynamic "network_profile" {
    for_each = var.network_profile != null ? [var.network_profile] : []
    iterator = p
    content {
      dns_service_ip      = p.value.dns_service_ip
      network_policy      = p.value.network_policy
      network_plugin      = p.value.network_plugin
      network_plugin_mode = p.value.network_plugin_mode
      outbound_type       = p.value.outbound_type
      service_cidr        = p.value.service_cidr
      network_data_plane  = p.value.network_data_plane
      load_balancer_sku   = "standard"
      load_balancer_profile {
        outbound_ip_address_ids = var.outbound_ip_address_ids
        idle_timeout_in_minutes = p.value.idle_timeout_in_minutes
      }
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender_log_analytics_workspace_id != null ? [var.microsoft_defender_log_analytics_workspace_id] : []
    iterator = law
    content {
      log_analytics_workspace_id = law.value
    }
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [23, 0, 1, 2, 3, 4]
    }
    allowed {
      day   = "Monday"
      hours = [23, 0, 1, 2, 3, 4]
    }
    allowed {
      day   = "Tuesday"
      hours = [23, 0, 1, 2, 3, 4]
    }
    allowed {
      day   = "Wednesday"
      hours = [23, 0, 1, 2, 3, 4]
    }
    allowed {
      day   = "Thursday"
      hours = [23, 0, 1, 2, 3, 4]
    }
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aad_admin_group_ids
  }

  http_application_routing_enabled = false
  azure_policy_enabled             = var.addon_azure_policy_enabled

  dynamic "key_vault_secrets_provider" {
    for_each = var.addon_azure_key_vault_secrets_provider_enabled ? [true] : []

    content {
      secret_rotation_enabled = key_vault_secrets_provider.value
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [var.log_analytics_workspace_id] : []

    content {
      log_analytics_workspace_id      = oms_agent.value
      msi_auth_for_monitoring_enabled = var.oms_agent_msi_auth_for_monitoring_enabled
    }
  }

  ### Prometheus managed metrics
  dynamic "monitor_metrics" {
    for_each = var.enable_prometheus_monitor_metrics ? [1] : []
    content {
      annotations_allowed = var.monitor_metrics.annotations_allowed
      labels_allowed      = var.monitor_metrics.labels_allowed
    }
  }

  storage_profile {
    file_driver_enabled         = var.storage_profile_file_driver_enabled
    disk_driver_enabled         = var.storage_profile_disk_driver_enabled
    snapshot_controller_enabled = var.storage_profile_snapshot_controller_enabled
    blob_driver_enabled         = var.storage_profile_blob_driver_enabled
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      network_profile[0].load_balancer_profile[0].idle_timeout_in_minutes,
      upgrade_override[0].effective_until
    ]
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  count = var.user_node_pool_enabled ? 1 : 0

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id

  name = var.user_node_pool_name

  ### vm configuration
  vm_size = var.user_node_pool_vm_size
  # https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general
  os_disk_type            = var.user_node_pool_os_disk_type # Managed or Ephemeral
  os_disk_size_gb         = var.user_node_pool_os_disk_size_gb
  zones                   = var.user_node_pool_availability_zones
  ultra_ssd_enabled       = var.user_node_pool_ultra_ssd_enabled
  host_encryption_enabled = var.user_node_pool_enable_host_encryption
  os_type                 = "Linux"

  ### autoscaling
  auto_scaling_enabled = true
  node_count           = var.user_node_pool_node_count_min
  min_count            = var.user_node_pool_node_count_min
  max_count            = var.user_node_pool_node_count_max

  ### K8s node configuration
  max_pods                    = var.user_node_pool_max_pods
  node_labels                 = var.user_node_pool_node_labels
  node_taints                 = var.user_node_pool_node_taints
  temporary_name_for_rotation = "tmpnode"

  ### networking
  vnet_subnet_id         = var.network_profile.network_plugin_mode == "overlay" ? var.vnet_user_subnet_id : var.vnet_subnet_id
  node_public_ip_enabled = false

  upgrade_settings {
    max_surge                = var.upgrade_settings_max_surge
    drain_timeout_in_minutes = var.user_node_pool_upgrade_settings_drain_timeout_in_minutes
  }

  tags = merge(var.tags, var.user_node_pool_tags)

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

#
# Role Assigments
#
moved {
  from = azurerm_role_assignment.aks
  to   = azurerm_role_assignment.oms_agent_monitoring_metrics
}

resource "azurerm_role_assignment" "oms_agent_monitoring_metrics" {
  count = var.log_analytics_workspace_id != null && var.oms_agent_monitoring_metrics_role_assignment_enabled ? 1 : 0

  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.this]

}

resource "azurerm_role_assignment" "vnet_role" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.this]

}

resource "azurerm_role_assignment" "vnet_outbound_role" {
  for_each = toset(var.outbound_ip_address_ids)

  scope                = each.key
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.this]

}
