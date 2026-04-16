variable "name" {
  type        = string
  description = "(Required) Cluster name"
}

variable "dns_prefix" {
  type        = string
  description = "(Required) DNS prefix specified when creating the managed cluster. Changing this forces a new resource to be created."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) Resource group name."
}

variable "location" {
  type = string
}

variable "aad_admin_group_ids" {
  description = "IDs of the Azure AD group for cluster-admin access"
  type        = list(string)
}

#
# 🤖 System node pool
#

variable "system_node_pool_name" {
  type        = string
  description = "(Required) The name which should be used for the default Kubernetes Node Pool. Changing this forces a new resource to be created."
  validation {
    condition = (
      length(var.system_node_pool_name) <= 12
    )
    error_message = "Max length is 12 chars."
  }
}

variable "system_node_pool_vm_size" {
  type        = string
  description = "(Required) The size of the Virtual Machine, such as Standard_B4ms or Standard_D4s_vX. See https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/134840344/Best+practice+su+prodotti"
}

variable "system_node_pool_os_disk_type" {
  type        = string
  description = "(Optional) The type of disk which should be used for the Operating System. Possible values are Ephemeral and Managed. Defaults to Managed."
  default     = "Ephemeral"
}

variable "system_node_pool_os_disk_size_gb" {
  type        = number
  description = "(Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
}

variable "system_node_pool_node_count_min" {
  type        = number
  description = "(Required) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000."
}

variable "system_node_pool_node_count_max" {
  type        = number
  description = "(Required) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000."
}

variable "system_node_pool_max_pods" {
  type        = number
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  default     = 250
}

variable "system_node_pool_node_labels" {
  type        = map(any)
  description = "(Optional) A map of Kubernetes labels which should be applied to nodes in the Default Node Pool. Changing this forces a new resource to be created."
  default     = {}
}

variable "system_node_pool_enable_host_encryption" {
  type        = bool
  description = "(Optional) Should the nodes in the Default Node Pool have host encryption enabled? Defaults to true."
  default     = true
}

variable "system_node_pool_only_critical_addons_enabled" {
  type        = bool
  description = "(Optional) Enabling this option will taint default node pool with CriticalAddonsOnly=true:NoSchedule taint. Changing this forces a new resource to be created."
  default     = true
}

variable "system_node_pool_ultra_ssd_enabled" {
  type        = bool
  description = "(Optional) Used to specify whether the UltraSSD is enabled in the Default Node Pool. Defaults to false."
  default     = false
}

variable "system_node_pool_availability_zones" {
  type        = list(string)
  description = "(Optional) List of availability zones for system node pool"
  default     = ["1", "2", "3"]
}

variable "system_node_pool_tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the Node Pool."
  default     = {}
}

variable "system_node_pool_upgrade_settings_drain_timeout_in_minutes" {
  type        = string
  default     = 30
  description = "(Optional) The amount of time in minutes to wait on eviction of pods and graceful termination per node. This eviction wait time honors pod disruption budgets for upgrades. If this time is exceeded, the upgrade fails. Unsetting this after configuring it will force a new resource to be created."
}

### <END SYSTEM NODE POOL/>

#
# 👤 User node pool
#
variable "user_node_pool_enabled" {
  type        = bool
  description = "Is user node pool enabled?"
  default     = false
}

variable "user_node_pool_name" {
  type        = string
  description = "(Required) The name which should be used for the default Kubernetes Node Pool. Changing this forces a new resource to be created."
  validation {
    condition = (
      length(var.user_node_pool_name) <= 12
    )
    error_message = "Max length is 12 chars."
  }
  default = ""
}

variable "user_node_pool_vm_size" {
  type        = string
  description = "(Required) The size of the Virtual Machine, such as Standard_B4ms or Standard_D4s_vX. See https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/134840344/Best+practice+su+prodotti"
  default     = ""
}

variable "user_node_pool_os_disk_type" {
  type        = string
  description = "(Optional) The type of disk which should be used for the Operating System. Possible values are Ephemeral and Managed. Defaults to Managed."
  default     = "Ephemeral"
}

variable "user_node_pool_os_disk_size_gb" {
  type        = number
  description = "(Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  default     = 0
}

variable "user_node_pool_node_count_min" {
  type        = number
  description = "(Required) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000."
  default     = 0
}

variable "user_node_pool_node_count_max" {
  type        = number
  description = "(Required) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000."
  default     = 0
}

variable "user_node_pool_max_pods" {
  type        = number
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  default     = 250
}

variable "user_node_pool_node_labels" {
  type        = map(any)
  description = "(Optional) A map of Kubernetes labels which should be applied to nodes in the Default Node Pool. Changing this forces a new resource to be created."
  default     = {}
}

variable "user_node_pool_node_taints" {
  type        = list(string)
  description = "(Optional) A list of Kubernetes taints which should be applied to nodes in the agent pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  default     = []
}

variable "user_node_pool_enable_host_encryption" {
  type        = bool
  description = "(Optional) Should the nodes in the Default Node Pool have host encryption enabled? Defaults to true."
  default     = false
}

variable "user_node_pool_ultra_ssd_enabled" {
  type        = bool
  description = "(Optional) Used to specify whether the UltraSSD is enabled in the Default Node Pool. Defaults to false."
  default     = false
}

variable "user_node_pool_availability_zones" {
  type        = list(string)
  description = "(Optional) List of availability zones for user node pool"
  default     = ["1", "2", "3"]
}

variable "user_node_pool_tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the Node Pool."
  default     = {}
}

variable "user_node_pool_upgrade_settings_drain_timeout_in_minutes" {
  type        = string
  default     = 30
  description = "(Optional) The amount of time in minutes to wait on eviction of pods and graceful termination per node. This eviction wait time honors pod disruption budgets for upgrades. If this time is exceeded, the upgrade fails. Unsetting this after configuring it will force a new resource to be created."
}

### END USER NODE POOL

variable "upgrade_settings_max_surge" {
  type        = string
  description = "The maximum number or percentage of nodes which will be added to the Node Pool size during an upgrade."
  default     = "33%"
}

variable "sku_tier" {
  type        = string
  description = "(Optional) The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid (which includes the Uptime SLA)"
  default     = "Free"
}

variable "kubernetes_version" {
  type        = string
  description = "(Required) Version of Kubernetes specified when creating the AKS managed cluster."
}

#
# ☁️ Network
#
variable "private_cluster_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located."
}

variable "vnet_id" {
  type        = string
  description = "(Required) Virtual network id, where the k8s cluster is deployed."
}

variable "vnet_subnet_id" {
  type        = string
  description = "(Optional) The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
  default     = null
}
variable "vnet_user_subnet_id" {
  type        = string
  description = "(Optional) The ID of a Subnet where the Kubernetes User Node Pool should exist. Changing this forces a new resource to be created."
  default     = null
}

variable "aks_gateway_api" {
  type = object({
    enabled      = optional(bool, false)
    gateway_id   = optional(string, null)
    gateway_name = optional(string, null)
    subnet_cidr  = optional(string, null)
    subnet_id    = optional(string, null)
  })
  default     = {}
  description = "(Optional) The Application Gateway associated with the ingress controller deployed to this Kubernetes Cluster."
  validation {
    condition = (
      !var.aks_gateway_api.enabled ? true : (
        count([
          for v in [
            var.aks_gateway_api.gateway_id,
            var.aks_gateway_api.gateway_name,
            var.aks_gateway_api.subnet_cidr,
            var.aks_gateway_api.subnet_id
          ] : v if v != null
        ]) == 1
      )
    )
    error_message = "Exactly one of gateway_id, gateway_name, subnet_id, or subnet_cidr must be specified."
  }
}

variable "automatic_channel_upgrade" {
  type        = string
  description = "(Optional) The upgrade channel for this Kubernetes Cluster. Possible values are patch, rapid, node-image and stable. Omitting this field sets this value to none."
  default     = null
}

variable "node_os_upgrade_channel" {
  type        = string
  description = "(Optional) The upgrade channel for this Kubernetes Cluster Nodes' OS Image. Possible values are Unmanaged, SecurityPatch, NodeImage and None."
  default     = "None"
}

### Cluster auto upgrade
variable "force_upgrade_enabled" {
  type        = bool
  description = "(Optional) If set to true, cluster will be forced to upgrade even if the latest version of the control plane and agents is not available."
  default     = false
}

variable "network_profile" {
  type = object({
    dns_service_ip          = optional(string, "10.2.0.10")    # e.g. '10.2.0.10'. IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)
    network_policy          = optional(string, "azure")        # e.g. 'azure'. Sets up network policy to be used with Azure CNI. Currently supported values are calico and azure.
    network_plugin          = optional(string, "azure")        # e.g. 'azure'. Network plugin to use for networking. Currently supported values are azure and kubenet
    network_plugin_mode     = optional(string, null)           # e.g. 'azure'. Network plugin mode to use for networking. Currently supported value is overlay
    outbound_type           = optional(string, "loadBalancer") # e.g. 'loadBalancer'. The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer, userDefinedRouting, managedNATGateway and userAssignedNATGateway. Defaults to loadBalancer
    service_cidr            = optional(string, "10.2.0.0/16")  # e.g. '10.2.0.0/16'. The Network Range used by the Kubernetes service
    network_data_plane      = optional(string, "azure")        # e.g. 'azure'. (Optional) Specifies the data plane used for building the Kubernetes network. Possible values are azure and cilium. Defaults to azure. Disabling this forces a new resource to be created.
    idle_timeout_in_minutes = optional(string, 30)             # e.g. 'idle_timeout_in_minutes'. (Optional) Desired outbound flow idle timeout in minutes for the cluster load balancer. Must be between 4 and 100 inclusive. Defaults to 30.
  })
  default = {
    dns_service_ip          = "10.2.0.10"
    network_policy          = "azure"
    network_plugin          = "azure"
    network_plugin_mode     = null
    outbound_type           = "loadBalancer"
    service_cidr            = "10.2.0.0/16"
    network_data_plane      = "azure"
    idle_timeout_in_minutes = 30
  }
  description = "See variable description to understand how to use it, and see examples"
}

variable "outbound_ip_address_ids" {
  type        = list(string)
  default     = []
  description = "The ID of the Public IP Addresses which should be used for outbound communication for the cluster load balancer."
}

#
# addons
#
variable "addon_azure_policy_enabled" {
  type        = bool
  description = "Should the Azure Policy addon be enabled for this Node Pool? "
  default     = false
}

variable "addon_azure_key_vault_secrets_provider_enabled" {
  type        = bool
  description = "Should the Azure Secrets Store CSI addon be enabled for this Node Pool? "
  default     = false
}

variable "monitor_metrics" {
  type = object({
    annotations_allowed = optional(string, null)
    labels_allowed      = optional(string, null)
  })
  default = {
    annotations_allowed = null
    labels_allowed      = null
  }
  description = "(Optional) Specifies a comma-separated list of Kubernetes annotation keys that will be used in the resource's labels metric."
}

# The sku_tier must be set to Standard or Premium to enable this feature.
# Enabling this will add Kubernetes Namespace and Deployment details to the Cost Analysis views in the Azure portal.
variable "cost_analysis_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Should cost analysis be enabled for this Kubernetes Cluster? Defaults to false."
}

#
# 📄 Logs
#
variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics Workspace which the OMS Agent should send data to."
  default     = null
}

variable "microsoft_defender_log_analytics_workspace_id" {
  type        = string
  description = "Specifies the ID of the Log Analytics Workspace where the audit logs collected by Microsoft Defender should be sent to"
  default     = null
}

#
# 🚓 Security
#
variable "sec_log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log analytics workspace security (it should be in a different subscription)."
}

variable "sec_storage_id" {
  type        = string
  default     = null
  description = "Storage Account security (it should be in a different subscription)."
}

variable "tags" {
  type = map(any)
}

variable "workload_identity_enabled" {
  type        = bool
  description = "(Optional) Specifies whether Azure AD Workload Identity should be enabled for the Cluster. Defaults to false."
  default     = false
}

variable "oidc_issuer_enabled" {
  type        = bool
  description = "(Optional) Enable or Disable the OIDC issuer URL"
  default     = false
}

#
# Storage profile
#
variable "storage_profile_blob_driver_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is the Blob CSI driver enabled? Defaults to false"
}

variable "storage_profile_file_driver_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Is the File CSI driver enabled? Defaults to true"
}

variable "storage_profile_snapshot_controller_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Is the Snapshot Controller enabled? Defaults to true"
}

variable "storage_profile_disk_driver_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Is the Disk CSI driver enabled? Defaults to true"
}

### Monitoring
variable "oms_agent_msi_auth_for_monitoring_enabled" {
  type        = bool
  description = "(Optional) Is managed identity authentication for monitoring enabled? Default false"
  default     = false
}

variable "oms_agent_monitoring_metrics_role_assignment_enabled" {
  type        = bool
  description = "Enabled oms agent monitoring metrics roles"
  default     = true
}

### Prometheus managed
variable "enable_prometheus_monitor_metrics" {
  description = "Enable or disable Prometheus managed metrics"
  type        = bool
  default     = false
}


# node os maintenance window. if disabled, schedules a maintenance window for a very far away date
variable "maintenance_windows_node_os" {
  type = object({
    enabled      = optional(bool, false)
    day_of_month = optional(number, 0)
    day_of_week  = optional(string, "Sunday")
    duration     = optional(number, 4)
    frequency    = optional(string, "Weekly")
    interval     = optional(number, 1)
    start_date   = optional(string, "2060-03-12T00:00:00Z")
    start_time   = optional(string, "00:00")
    utc_offset   = optional(string, "+00:00")
    week_index   = optional(string, "First")
  })
  default = {
    enabled      = false
    day_of_month = 0
    day_of_week  = "Sunday"
    duration     = 4
    frequency    = "Weekly"
    interval     = 1
    start_date   = "2060-03-12T00:00:00Z"
    start_time   = "00:00"
    utc_offset   = "+00:00"
    week_index   = "First"
  }
}

variable "workload_autoscaler_profile_keda_enabled" {
  type        = bool
  description = "(Optional) Enable or disable KEDA autoscaler"
  default     = false
}
variable "workload_autoscaler_profile_vertical_pod_autoscaler_enabled" {
  type        = bool
  description = "(Optional) Enable or disable Vertical Pod Autoscaler"
  default     = false
}

#
# Alerts
#
variable "default_metric_alerts" {
  description = <<EOD
  Map of name = criteria objects
  EOD

  type = map(object({
    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]
    aggregation = string
    # (Optional) Specifies the description of the scheduled metric rule.
    description = optional(string)
    # "Insights.Container/pods" "Insights.Container/nodes"
    metric_namespace = string
    metric_name      = string
    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]
    operator  = string
    threshold = number
    # Possible values are 0, 1, 2, 3 and 4. Defaults to 3.
    severity = optional(number)
    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H
    frequency = string
    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.
    window_size = string
    # Skip metrics validation
    skip_metric_validation = optional(bool, false)


    dimension = list(object(
      {
        name     = string
        operator = string
        values   = list(string)
      }
    ))
  }))

  default = {
    node_cpu_usage_percentage = {
      aggregation      = "Average"
      metric_namespace = "Microsoft.ContainerService/managedClusters"
      description      = "High node cpu usage"
      metric_name      = "node_cpu_usage_percentage"
      operator         = "GreaterThan"
      threshold        = 80
      severity         = 2
      frequency        = "PT15M"
      window_size      = "PT1H"
      dimension = [
        {
          name     = "node"
          operator = "Include"
          values   = ["*"]
        }
      ]
    }

    node_memory_working_set_percentage = {
      aggregation      = "Average"
      metric_namespace = "Microsoft.ContainerService/managedClusters"
      description      = "High node memory usage"
      metric_name      = "node_memory_working_set_percentage"
      operator         = "GreaterThan"
      threshold        = 80
      severity         = 2
      frequency        = "PT15M"
      window_size      = "PT1H"
      dimension = [
        {
          name     = "node"
          operator = "Include"
          values   = ["*"]
        }
      ],
    }
  }
}

variable "custom_metric_alerts" {
  description = <<EOD
  Map of name = criteria objects
  EOD

  default = {}

  type = map(object({
    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]
    aggregation = string
    # "Insights.Container/pods" "Insights.Container/nodes"
    metric_namespace = string
    metric_name      = string
    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]
    operator  = string
    threshold = number
    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H
    frequency = string
    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.
    window_size = string
    # Skip metrics validation
    skip_metric_validation = optional(bool, false)

    dimension = list(object(
      {
        name     = string
        operator = string
        values   = list(string)
      }
    ))
  }))
}


variable "custom_logs_alerts" {
  description = <<EOD
  Map of name = criteria objects
  EOD

  default = {}

  type = map(object({
    # (Optional) Specifies the display name of the alert rule.
    display_name = string
    # (Optional) Specifies the description of the scheduled query rule.
    description = string
    # Assuming each.value includes this attribute for Kusto Query Language (KQL)
    query = string
    # (Required) Severity of the alert. Should be an integer between 0 and 4.
    # Value of 0 is severest.
    severity = number
    # (Required) Specifies the period of time in ISO 8601 duration format on
    # which the Scheduled Query Rule will be executed (bin size).
    # If evaluation_frequency is PT1M, possible values are PT1M, PT5M, PT10M,
    # PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, and PT6H. Otherwise,
    # possible values are PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H,
    # PT4H, PT5H, PT6H, P1D, and P2D.
    window_duration = optional(string)
    # (Optional) How often the scheduled query rule is evaluated, represented
    # in ISO 8601 duration format. Possible values are PT1M, PT5M, PT10M, PT15M,
    # PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H, P1D.
    evaluation_frequency = string
    # Evaluation operation for rule - 'GreaterThan', GreaterThanOrEqual',
    # 'LessThan', or 'LessThanOrEqual'.
    operator = string
    # Result or count threshold based on which rule should be triggered.
    # Values must be between 0 and 10000 inclusive.
    threshold = number
    # (Required) The type of aggregation to apply to the data points in
    # aggregation granularity. Possible values are Average, Count, Maximum,
    # Minimum,and Total.
    time_aggregation_method = string
    # (Optional) Specifies the column containing the resource ID. The content
    # of the column must be an uri formatted as resource ID.
    resource_id_column = optional(string)

    # (Optional) Specifies the column containing the metric measure number.
    metric_measure_column = optional(string)

    dimension = list(object(
      {
        # (Required) Name of the dimension.
        name = string
        # (Required) Operator for dimension values. Possible values are
        # Exclude,and Include.
        operator = string
        # (Required) List of dimension values. Use a wildcard * to collect all.
        values = list(string)
      }
    ))

    # (Required) Specifies the number of violations to trigger an alert.
    # Should be smaller or equal to number_of_evaluation_periods.
    # Possible value is integer between 1 and 6.
    minimum_failing_periods_to_trigger_alert = number
    # (Required) Specifies the number of aggregated look-back points.
    # The look-back time window is calculated based on the aggregation
    # granularity window_duration and the selected number of aggregated points.
    # Possible value is integer between 1 and 6.
    number_of_evaluation_periods = number

    # (Optional) Specifies the flag that indicates whether the alert should
    # be automatically resolved or not. Value should be true or false.
    # The default is false.
    auto_mitigation_enabled = optional(bool)
    # (Optional) Specifies the flag which indicates whether this scheduled
    # query rule check if storage is configured. Value should be true or false.
    # The default is false.
    workspace_alerts_storage_enabled = optional(bool)
    # (Optional) Specifies the flag which indicates whether the provided
    # query should be validated or not. The default is false.
    skip_query_validation = optional(bool)
  }))
}


variable "action" {
  description = "The ID of the Action Group and optional map of custom string properties to include with the post webhook operation."
  type = set(object(
    {
      action_group_id    = string
      webhook_properties = map(string)
    }
  ))
  default = []
}

variable "alerts_enabled" {
  type        = bool
  default     = true
  description = "Should Metrics Alert be enabled?"
}


