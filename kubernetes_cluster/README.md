# kubernetes_cluster

Module that allows the creation of an AKS cluster.

## Architecture

![architecture](./docs/module-arch.drawio.png)

## Migration v3 -> v4

Deleted resources:
* null_resource.enable_pod_identity

## Metrics Monitor/Alerts

By default the modules have a default set of metric alerts.

* If you want is possible to add new **custom metrics alerts** using the varible: `custom_metric_alerts`
* Or override the **default metrics alert** using the variable: `default_metric_alerts`. (is prefered to add new metrics)

After **v8.57.0**:
* If you want is possible to add new **custom metrics alerts** using the varible: `custom_logs_alerts`
* Or override the **default logs alert** using the variable: `default_logs_alerts`. (is prefered to add new metrics)

This changes is mandatory for the decommissioned metrics alert resource on Azure from May, 2024: [read_more](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-metric-alerts?tabs=portal#legacy-container-insights-metric-alerts-preview).

List of our metrics alert decommissioned on this module after **v8.57.0**:

- node_disk
- node_not_ready

## How to use it

### Variable definition example

```hcl
#
# ⛴ AKS PROD
#
variable "aks_enabled" {
  type        = bool
  description = "Must be the aks cluster created?"
  default     = true
}

variable "aks_private_cluster_enabled" {
  type        = bool
  description = "Enable or not public visibility of AKS"
  default     = false
}

variable "aks_num_outbound_ips" {
  type        = number
  default     = 1
  description = "How many outbound ips allocate for AKS cluster"
}

variable "aks_availability_zones" {
  type        = list(number)
  description = "A list of Availability Zones across which the Node Pool should be spread."
  default     = []
}

variable "aks_vm_size" {
  type        = string
  default     = "Standard_DS3_v2"
  description = "The size of the AKS Virtual Machine in the Node Pool."
}

variable "aks_max_pods" {
  type        = number
  description = "The maximum number of pods"
  default     = 100
}

variable "aks_enable_auto_scaling" {
  type        = bool
  description = "Should the Kubernetes Auto Scaler be enabled for this Node Pool? "
  default     = false
}

variable "aks_node_count" {
  type        = number
  description = "The initial number of the AKS nodes which should exist in this Node Pool."
  default     = 1
}

variable "aks_node_min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000"
  default     = null
}

variable "aks_node_max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000"
  default     = null
}

variable "aks_kubernetes_version" {
  type        = string
  description = "Kubernetes version of cluster aks"
}

variable "aks_sku_tier" {
  type        = string
  description = "The SKU Tier that should be used for this Kubernetes Cluster."
  default     = "Free"
}

variable "aks_reverse_proxy_ip" {
  type        = string
  default     = "127.0.0.1"
  description = "AKS external ip. Also the ingress-nginx-controller external ip. Value known after installing the ingress controller."
}

variable "aks_metric_alerts_default" {
  description = <<EOD
  Map of name = criteria objects
  EOD

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

    dimension = list(object(
      {
        name     = string
        operator = string
        values   = list(string)
      }
    ))
  }))

  default = {
    node_cpu = {
      aggregation      = "Average"
      metric_namespace = "Insights.Container/nodes"
      metric_name      = "cpuUsagePercentage"
      operator         = "GreaterThan"
      threshold        = 80
      frequency        = "PT1M"
      window_size      = "PT5M"
      dimension = [
        {
          name     = "host"
          operator = "Include"
          values   = ["*"]
        }
      ],
    }
    node_memory = {
      aggregation      = "Average"
      metric_namespace = "Insights.Container/nodes"
      metric_name      = "memoryWorkingSetPercentage"
      operator         = "GreaterThan"
      threshold        = 80
      frequency        = "PT1M"
      window_size      = "PT5M"
      dimension = [
        {
          name     = "host"
          operator = "Include"
          values   = ["*"]
        }
      ],
    }
  }
}

locals {
    aks_logs_alerts = {
      pods_oomkilled = {
        display_name            = "${module.aks.name}-POD-OMMKILLED"
        description             = "Detect if any pod is OOMKilled"
        query                   = <<-KQL
          KubePodInventory
          | where PodStatus != "running"
          | extend ContainerLastStatusJSON = parse_json(ContainerLastStatus)
          | extend FinishedAt = todatetime(ContainerLastStatusJSON.finishedAt)
          | where ContainerLastStatusJSON.reason == "OOMKilled"
          | distinct PodUid, Namespace, ControllerName, ContainerLastStatus, FinishedAt
          | order by FinishedAt asc
        KQL
        severity                = 1
        window_duration         = "PT15M"
        evaluation_frequency    = "PT5M"
        operator                = "GreaterThan"
        threshold               = 1
        time_aggregation_method = "Count"
        resource_id_column      = "ControllerName"
        metric_measure_column   = null
        dimension = [
          {
            name     = "ControllerName"
            operator = "Include"
            values   = ["*"]
          },
          {
            name     = "Namespace"
            operator = "Exclude"
            values = [
              "kube-system",
              "default"
            ]
          }
        ]
        minimum_failing_periods_to_trigger_alert = 1
        number_of_evaluation_periods             = 1
        auto_mitigation_enabled                  = true
        skip_query_validation                    = true
    }
  }
}

variable "aks_alerts_enabled" {
  type        = bool
  default     = true
  description = "Aks alert enabled?"
}

variable "aks_system_node_pool" {
  type = object({
    name            = string,
    vm_size         = string,
    os_disk_type    = string,
    os_disk_size_gb = string,
    node_count_min  = number,
    node_count_max  = number,
    node_labels     = map(any),
    node_tags       = map(any)
  })
  description = "AKS node pool system configuration"
}

variable "aks_user_node_pool" {
  type = object({
    enabled         = bool,
    name            = string,
    vm_size         = string,
    os_disk_type    = string,
    os_disk_size_gb = string,
    node_count_min  = number,
    node_count_max  = number,
    node_labels     = map(any),
    node_taints     = list(string),
    node_tags       = map(any),
  })
  description = "AKS node pool user configuration"
}

variable "aks_addons" {
  type = object({
    azure_policy                     = bool,
    azure_key_vault_secrets_provider = bool,
  })

  default = {
    azure_key_vault_secrets_provider = true
    azure_policy                     = true
  }

  description = "Aks addons configuration"
}

#
# Kubernetes Cluster Configurations
#
variable "k8s_kube_config_path_prefix" {
  type    = string
  default = "~/.kube"
}

variable "ingress_replica_count" {
  type = string
}

variable "ingress_load_balancer_ip" {
  type = string
}

variable "default_service_port" {
  type    = number
  default = 8080
}

variable "nginx_helm_version" {
  type        = string
  description = "NGINX helm verison"
}

variable "keda_helm_version" {
  type = string
}
```

### Variables values

```hcl
rg_vnet_aks_name           = "dvopla-d-neu-dev01-aks-vnet-rg"
vnet_aks_name              = "dvopla-d-neu-dev01-aks-vnet"
public_ip_aksoutbound_name = "dvopla-d-dev01-aksoutbound-pip-1"

aks_enabled                 = true
aks_private_cluster_enabled = false
aks_alerts_enabled          = false
aks_kubernetes_version      = "1.23.8"
aks_system_node_pool = {
  name            = "dvldev01sys",
  vm_size         = "Standard_B2ms",
  os_disk_type    = "Managed",
  os_disk_size_gb = 75,
  node_count_min  = 1,
  node_count_max  = 3,
  node_labels     = { node_name : "aks-dev01-sys", node_type : "system" },
  node_tags       = { node_tag_1 : "1" },
}
aks_user_node_pool = {
  enabled         = true,
  name            = "dvldev01usr",
  vm_size         = "Standard_B4ms",
  os_disk_type    = "Managed",
  os_disk_size_gb = 75,
  node_count_min  = 1,
  node_count_max  = 5,
  node_labels     = { node_name : "aks-dev01-user", node_type : "user" },
  node_taints     = [],
  node_tags       = { node_tag_2 : "2" },
}
aks_addons = {
  azure_policy                     = true,
  azure_key_vault_secrets_provider = true,
}

ingress_replica_count = "2"
# This is the k8s ingress controller ip. It must be in the aks subnet range.
ingress_load_balancer_ip = "10.11.100.250"
nginx_helm_version       = "4.1.0"
keda_helm_version        = "2.6.2"

```

### AKS Cluster

```hcl
  resource "azurerm_resource_group" "rg_aks" {
    name     = local.aks_rg_name
    location = var.location
    tags     = var.tags
  }

  module "aks" {
    source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//kubernetes_cluster?ref=v8.8.0"

    count = var.aks_enabled ? 1 : 0

    name                       = local.aks_cluster_name
    location                   = azurerm_resource_group.rg_aks.location
    dns_prefix                 = "${local.project}-aks"
    resource_group_name        = azurerm_resource_group.rg_aks.name
    kubernetes_version         = var.aks_kubernetes_version
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.id
    sku_tier                   = var.aks_sku_tier

    #
    # 🤖 System node pool
    #
    system_node_pool_name = var.aks_system_node_pool.name
    ### vm configuration
    system_node_pool_vm_size         = var.aks_system_node_pool.vm_size
    system_node_pool_os_disk_type    = var.aks_system_node_pool.os_disk_type
    system_node_pool_os_disk_size_gb = var.aks_system_node_pool.os_disk_size_gb
    system_node_pool_node_count_min  = var.aks_system_node_pool.node_count_min
    system_node_pool_node_count_max  = var.aks_system_node_pool.node_count_max
    ### K8s node configuration
    system_node_pool_node_labels = var.aks_system_node_pool.node_labels
    system_node_pool_tags        = var.aks_system_node_pool.node_tags

    #
    # 👤 User node pool
    #
    user_node_pool_enabled = var.aks_user_node_pool.enabled
    user_node_pool_name    = var.aks_user_node_pool.name
    ### vm configuration
    user_node_pool_vm_size         = var.aks_user_node_pool.vm_size
    user_node_pool_os_disk_type    = var.aks_user_node_pool.os_disk_type
    user_node_pool_os_disk_size_gb = var.aks_user_node_pool.os_disk_size_gb
    user_node_pool_node_count_min  = var.aks_user_node_pool.node_count_min
    user_node_pool_node_count_max  = var.aks_user_node_pool.node_count_max
    ### K8s node configuration
    user_node_pool_node_labels = var.aks_user_node_pool.node_labels
    user_node_pool_node_taints = var.aks_user_node_pool.node_taints
    user_node_pool_tags        = var.aks_user_node_pool.node_tags
    # end user node pool

    #
    # ☁️ Network
    #
    vnet_id        = data.azurerm_virtual_network.vnet_aks.id
    vnet_subnet_id = module.snet_aks.id

    outbound_ip_address_ids = [data.azurerm_public_ip.pip_aks_outboud.id]
    private_cluster_enabled = var.aks_private_cluster_enabled
    network_profile = {
      docker_bridge_cidr = "172.17.0.1/16"
      dns_service_ip     = "10.250.0.10"
      network_plugin     = "azure"
      network_policy     = "azure"
      outbound_type      = "loadBalancer"
      service_cidr       = "10.250.0.0/16"
    }
    # end network
    
    rbac_enabled        = true
    aad_admin_group_ids = var.env_short == "d" ? [data.azuread_group.adgroup_admin.object_id, data.azuread_group.adgroup_developers.object_id, data.azuread_group.adgroup_externals.object_id] : [data.azuread_group.adgroup_admin.object_id]

    addon_azure_policy_enabled                     = var.aks_addons.azure_policy
    addon_azure_key_vault_secrets_provider_enabled = var.aks_addons.azure_key_vault_secrets_provider

    default_metric_alerts = var.aks_metric_alerts_default
    custom_metric_alerts  = var.aks_metric_alerts_custom
    custom_logs_alerts    = local.aks_logs_alerts

    alerts_enabled = var.aks_alerts_enabled
    action = [
      {
        action_group_id    = data.azurerm_monitor_action_group.slack.id
        webhook_properties = null
      },
      {
        action_group_id    = data.azurerm_monitor_action_group.email.id
        webhook_properties = null
      }
    ]
    tags = var.tags

    depends_on = [
      module.snet_aks,
      data.azurerm_public_ip.pip_aks_outboud,
      data.azurerm_virtual_network.vnet_aks
    ]
  }

  #
  # ACR connection
  #
  # add the role to the identity the kubernetes cluster was assigned
  resource "azurerm_role_assignment" "aks_to_acr" {
    scope                = data.azurerm_container_registry.acr.id
    role_definition_name = "AcrPull"
    principal_id         = module.aks[0].kubelet_identity_id
  }

  #
  # Vnet Link
  #

  # vnet needs a vnet link with aks private dns zone
  # aks terrform module doesn't export private dns zone
  resource "null_resource" "create_vnet_core_aks_link" {

    count = var.aks_enabled && var.aks_private_cluster_enabled ? 1 : 0
    triggers = {
      cluster_name = module.aks[0].name
      vnet_id      = data.azurerm_virtual_network.vnet_core.id
      vnet_name    = data.azurerm_virtual_network.vnet_core.name
    }

    provisioner "local-exec" {
      command = <<EOT
        dns_zone_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{name:name}")
        dns_zone_resource_group_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{resourceGroup:resourceGroup}")
        az network private-dns link vnet create \
          --name ${self.triggers.vnet_name} \
          --registration-enabled false \
          --resource-group $dns_zone_resource_group_name \
          --virtual-network ${self.triggers.vnet_id} \
          --zone-name $dns_zone_name
      EOT
    }

    provisioner "local-exec" {
      when    = destroy
      command = <<EOT
        dns_zone_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{name:name}")
        dns_zone_resource_group_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{resourceGroup:resourceGroup}")
        az network private-dns link vnet delete \
          --name ${self.triggers.vnet_name} \
          --resource-group $dns_zone_resource_group_name \
          --zone-name $dns_zone_name \
          --yes
      EOT
    }

    depends_on = [
      module.aks
    ]
  }

```

## Migration from v2

1️⃣ Arguments changed:

* `availability_zones` -> `zones`

2️⃣ Delete/re-import state `module.aks[0].azurerm_kubernetes_cluster_node_pool.this[0]`

Unfortunatelly is impossible to use `zones` if `availability_zones` is already use, so you need to delete the state record and re-import

```bash
sh terraform.sh import dev01 'module.aks[0].azurerm_kubernetes_cluster_node_pool.this[0]' /subscriptions/22222222-79bf-48fa-831e-111111111/resourceGroups/dvopla-d-neu-dev01-aks-rg/providers/Microsoft.ContainerService/managedClusters/dvopla-d-neu-dev01-aks/agentPools/dvldev01usr
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_monitor_diagnostic_setting.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_role_assignment.oms_agent_monitoring_metrics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.vnet_outbound_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.vnet_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [null_resource.b_series_not_ephemeral_system_check](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.b_series_not_ephemeral_user_check](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.workload_identity_oidc_issuer_enabled_check](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aad_admin_group_ids"></a> [aad\_admin\_group\_ids](#input\_aad\_admin\_group\_ids) | IDs of the Azure AD group for cluster-admin access | `list(string)` | n/a | yes |
| <a name="input_action"></a> [action](#input\_action) | The ID of the Action Group and optional map of custom string properties to include with the post webhook operation. | <pre>set(object(<br/>    {<br/>      action_group_id    = string<br/>      webhook_properties = map(string)<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_addon_azure_key_vault_secrets_provider_enabled"></a> [addon\_azure\_key\_vault\_secrets\_provider\_enabled](#input\_addon\_azure\_key\_vault\_secrets\_provider\_enabled) | Should the Azure Secrets Store CSI addon be enabled for this Node Pool? | `bool` | `false` | no |
| <a name="input_addon_azure_policy_enabled"></a> [addon\_azure\_policy\_enabled](#input\_addon\_azure\_policy\_enabled) | Should the Azure Policy addon be enabled for this Node Pool? | `bool` | `false` | no |
| <a name="input_alerts_enabled"></a> [alerts\_enabled](#input\_alerts\_enabled) | Should Metrics Alert be enabled? | `bool` | `true` | no |
| <a name="input_automatic_channel_upgrade"></a> [automatic\_channel\_upgrade](#input\_automatic\_channel\_upgrade) | (Optional) The upgrade channel for this Kubernetes Cluster. Possible values are patch, rapid, node-image and stable. Omitting this field sets this value to none. | `string` | `null` | no |
| <a name="input_cost_analysis_enabled"></a> [cost\_analysis\_enabled](#input\_cost\_analysis\_enabled) | (Optional) Should cost analysis be enabled for this Kubernetes Cluster? Defaults to false. | `bool` | `false` | no |
| <a name="input_custom_logs_alerts"></a> [custom\_logs\_alerts](#input\_custom\_logs\_alerts) | Map of name = criteria objects | <pre>map(object({<br/>    # (Optional) Specifies the display name of the alert rule.<br/>    display_name = string<br/>    # (Optional) Specifies the description of the scheduled query rule.<br/>    description = string<br/>    # Assuming each.value includes this attribute for Kusto Query Language (KQL)<br/>    query = string<br/>    # (Required) Severity of the alert. Should be an integer between 0 and 4.<br/>    # Value of 0 is severest.<br/>    severity = number<br/>    # (Required) Specifies the period of time in ISO 8601 duration format on<br/>    # which the Scheduled Query Rule will be executed (bin size).<br/>    # If evaluation_frequency is PT1M, possible values are PT1M, PT5M, PT10M,<br/>    # PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, and PT6H. Otherwise,<br/>    # possible values are PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H,<br/>    # PT4H, PT5H, PT6H, P1D, and P2D.<br/>    window_duration = optional(string)<br/>    # (Optional) How often the scheduled query rule is evaluated, represented<br/>    # in ISO 8601 duration format. Possible values are PT1M, PT5M, PT10M, PT15M,<br/>    # PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H, P1D.<br/>    evaluation_frequency = string<br/>    # Evaluation operation for rule - 'GreaterThan', GreaterThanOrEqual',<br/>    # 'LessThan', or 'LessThanOrEqual'.<br/>    operator = string<br/>    # Result or count threshold based on which rule should be triggered.<br/>    # Values must be between 0 and 10000 inclusive.<br/>    threshold = number<br/>    # (Required) The type of aggregation to apply to the data points in<br/>    # aggregation granularity. Possible values are Average, Count, Maximum,<br/>    # Minimum,and Total.<br/>    time_aggregation_method = string<br/>    # (Optional) Specifies the column containing the resource ID. The content<br/>    # of the column must be an uri formatted as resource ID.<br/>    resource_id_column = optional(string)<br/><br/>    # (Optional) Specifies the column containing the metric measure number.<br/>    metric_measure_column = optional(string)<br/><br/>    dimension = list(object(<br/>      {<br/>        # (Required) Name of the dimension.<br/>        name = string<br/>        # (Required) Operator for dimension values. Possible values are<br/>        # Exclude,and Include.<br/>        operator = string<br/>        # (Required) List of dimension values. Use a wildcard * to collect all.<br/>        values = list(string)<br/>      }<br/>    ))<br/><br/>    # (Required) Specifies the number of violations to trigger an alert.<br/>    # Should be smaller or equal to number_of_evaluation_periods.<br/>    # Possible value is integer between 1 and 6.<br/>    minimum_failing_periods_to_trigger_alert = number<br/>    # (Required) Specifies the number of aggregated look-back points.<br/>    # The look-back time window is calculated based on the aggregation<br/>    # granularity window_duration and the selected number of aggregated points.<br/>    # Possible value is integer between 1 and 6.<br/>    number_of_evaluation_periods = number<br/><br/>    # (Optional) Specifies the flag that indicates whether the alert should<br/>    # be automatically resolved or not. Value should be true or false.<br/>    # The default is false.<br/>    auto_mitigation_enabled = optional(bool)<br/>    # (Optional) Specifies the flag which indicates whether this scheduled<br/>    # query rule check if storage is configured. Value should be true or false.<br/>    # The default is false.<br/>    workspace_alerts_storage_enabled = optional(bool)<br/>    # (Optional) Specifies the flag which indicates whether the provided<br/>    # query should be validated or not. The default is false.<br/>    skip_query_validation = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_metric_alerts"></a> [custom\_metric\_alerts](#input\_custom\_metric\_alerts) | Map of name = criteria objects | <pre>map(object({<br/>    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]<br/>    aggregation = string<br/>    # "Insights.Container/pods" "Insights.Container/nodes"<br/>    metric_namespace = string<br/>    metric_name      = string<br/>    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]<br/>    operator  = string<br/>    threshold = number<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H<br/>    frequency = string<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.<br/>    window_size = string<br/>    # Skip metrics validation<br/>    skip_metric_validation = optional(bool, false)<br/><br/>    dimension = list(object(<br/>      {<br/>        name     = string<br/>        operator = string<br/>        values   = list(string)<br/>      }<br/>    ))<br/>  }))</pre> | `{}` | no |
| <a name="input_default_metric_alerts"></a> [default\_metric\_alerts](#input\_default\_metric\_alerts) | Map of name = criteria objects | <pre>map(object({<br/>    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]<br/>    aggregation = string<br/>    # (Optional) Specifies the description of the scheduled metric rule.<br/>    description = optional(string)<br/>    # "Insights.Container/pods" "Insights.Container/nodes"<br/>    metric_namespace = string<br/>    metric_name      = string<br/>    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]<br/>    operator  = string<br/>    threshold = number<br/>    # Possible values are 0, 1, 2, 3 and 4. Defaults to 3.<br/>    severity = optional(number)<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H<br/>    frequency = string<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.<br/>    window_size = string<br/>    # Skip metrics validation<br/>    skip_metric_validation = optional(bool, false)<br/><br/><br/>    dimension = list(object(<br/>      {<br/>        name     = string<br/>        operator = string<br/>        values   = list(string)<br/>      }<br/>    ))<br/>  }))</pre> | <pre>{<br/>  "node_cpu_usage_percentage": {<br/>    "aggregation": "Average",<br/>    "description": "High node cpu usage",<br/>    "dimension": [<br/>      {<br/>        "name": "node",<br/>        "operator": "Include",<br/>        "values": [<br/>          "*"<br/>        ]<br/>      }<br/>    ],<br/>    "frequency": "PT15M",<br/>    "metric_name": "node_cpu_usage_percentage",<br/>    "metric_namespace": "Microsoft.ContainerService/managedClusters",<br/>    "operator": "GreaterThan",<br/>    "severity": 2,<br/>    "threshold": 80,<br/>    "window_size": "PT1H"<br/>  },<br/>  "node_memory_working_set_percentage": {<br/>    "aggregation": "Average",<br/>    "description": "High node memory usage",<br/>    "dimension": [<br/>      {<br/>        "name": "node",<br/>        "operator": "Include",<br/>        "values": [<br/>          "*"<br/>        ]<br/>      }<br/>    ],<br/>    "frequency": "PT15M",<br/>    "metric_name": "node_memory_working_set_percentage",<br/>    "metric_namespace": "Microsoft.ContainerService/managedClusters",<br/>    "operator": "GreaterThan",<br/>    "severity": 2,<br/>    "threshold": 80,<br/>    "window_size": "PT1H"<br/>  },<br/>  "pods_failed": {<br/>    "aggregation": "Average",<br/>    "description": "Pod state phase failed",<br/>    "dimension": [<br/>      {<br/>        "name": "phase",<br/>        "operator": "Include",<br/>        "values": [<br/>          "Failed"<br/>        ]<br/>      },<br/>      {<br/>        "name": "namespace",<br/>        "operator": "Include",<br/>        "values": [<br/>          "*"<br/>        ]<br/>      }<br/>    ],<br/>    "frequency": "PT15M",<br/>    "metric_name": "kube_pod_status_phase",<br/>    "metric_namespace": "Microsoft.ContainerService/managedClusters",<br/>    "operator": "GreaterThan",<br/>    "severity": 1,<br/>    "threshold": 0,<br/>    "window_size": "PT1H"<br/>  }<br/>}</pre> | no |
| <a name="input_dns_prefix"></a> [dns\_prefix](#input\_dns\_prefix) | (Required) DNS prefix specified when creating the managed cluster. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_enable_prometheus_monitor_metrics"></a> [enable\_prometheus\_monitor\_metrics](#input\_enable\_prometheus\_monitor\_metrics) | Enable or disable Prometheus managed metrics | `bool` | `false` | no |
| <a name="input_force_upgrade_enabled"></a> [force\_upgrade\_enabled](#input\_force\_upgrade\_enabled) | (Optional) If set to true, cluster will be forced to upgrade even if the latest version of the control plane and agents is not available. | `bool` | `false` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | (Required) Version of Kubernetes specified when creating the AKS managed cluster. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | The ID of the Log Analytics Workspace which the OMS Agent should send data to. | `string` | `null` | no |
| <a name="input_maintenance_windows_node_os"></a> [maintenance\_windows\_node\_os](#input\_maintenance\_windows\_node\_os) | node os maintenance window. if disabled, schedules a maintenance window for a very far away date | <pre>object({<br/>    enabled      = optional(bool, false)<br/>    day_of_month = optional(number, 0)<br/>    day_of_week  = optional(string, "Sunday")<br/>    duration     = optional(number, 4)<br/>    frequency    = optional(string, "Weekly")<br/>    interval     = optional(number, 1)<br/>    start_date   = optional(string, "2060-03-12T00:00:00Z")<br/>    start_time   = optional(string, "00:00")<br/>    utc_offset   = optional(string, "+00:00")<br/>    week_index   = optional(string, "First")<br/>  })</pre> | <pre>{<br/>  "day_of_month": 0,<br/>  "day_of_week": "Sunday",<br/>  "duration": 4,<br/>  "enabled": false,<br/>  "frequency": "Weekly",<br/>  "interval": 1,<br/>  "start_date": "2060-03-12T00:00:00Z",<br/>  "start_time": "00:00",<br/>  "utc_offset": "+00:00",<br/>  "week_index": "First"<br/>}</pre> | no |
| <a name="input_microsoft_defender_log_analytics_workspace_id"></a> [microsoft\_defender\_log\_analytics\_workspace\_id](#input\_microsoft\_defender\_log\_analytics\_workspace\_id) | Specifies the ID of the Log Analytics Workspace where the audit logs collected by Microsoft Defender should be sent to | `string` | `null` | no |
| <a name="input_monitor_metrics"></a> [monitor\_metrics](#input\_monitor\_metrics) | (Optional) Specifies a comma-separated list of Kubernetes annotation keys that will be used in the resource's labels metric. | <pre>object({<br/>    annotations_allowed = optional(string, null)<br/>    labels_allowed      = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "annotations_allowed": null,<br/>  "labels_allowed": null<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Cluster name | `string` | n/a | yes |
| <a name="input_network_profile"></a> [network\_profile](#input\_network\_profile) | See variable description to understand how to use it, and see examples | <pre>object({<br/>    dns_service_ip          = optional(string, "10.2.0.10")    # e.g. '10.2.0.10'. IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)<br/>    network_policy          = optional(string, "azure")        # e.g. 'azure'. Sets up network policy to be used with Azure CNI. Currently supported values are calico and azure.<br/>    network_plugin          = optional(string, "azure")        # e.g. 'azure'. Network plugin to use for networking. Currently supported values are azure and kubenet<br/>    network_plugin_mode     = optional(string, null)           # e.g. 'azure'. Network plugin mode to use for networking. Currently supported value is overlay<br/>    outbound_type           = optional(string, "loadBalancer") # e.g. 'loadBalancer'. The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer, userDefinedRouting, managedNATGateway and userAssignedNATGateway. Defaults to loadBalancer<br/>    service_cidr            = optional(string, "10.2.0.0/16")  # e.g. '10.2.0.0/16'. The Network Range used by the Kubernetes service<br/>    network_data_plane      = optional(string, "azure")        # e.g. 'azure'. (Optional) Specifies the data plane used for building the Kubernetes network. Possible values are azure and cilium. Defaults to azure. Disabling this forces a new resource to be created.<br/>    idle_timeout_in_minutes = optional(string, 30)             # e.g. 'idle_timeout_in_minutes'. (Optional) Desired outbound flow idle timeout in minutes for the cluster load balancer. Must be between 4 and 100 inclusive. Defaults to 30.<br/>  })</pre> | <pre>{<br/>  "dns_service_ip": "10.2.0.10",<br/>  "idle_timeout_in_minutes": 30,<br/>  "network_data_plane": "azure",<br/>  "network_plugin": "azure",<br/>  "network_plugin_mode": null,<br/>  "network_policy": "azure",<br/>  "outbound_type": "loadBalancer",<br/>  "service_cidr": "10.2.0.0/16"<br/>}</pre> | no |
| <a name="input_node_os_upgrade_channel"></a> [node\_os\_upgrade\_channel](#input\_node\_os\_upgrade\_channel) | (Optional) The upgrade channel for this Kubernetes Cluster Nodes' OS Image. Possible values are Unmanaged, SecurityPatch, NodeImage and None. | `string` | `"None"` | no |
| <a name="input_oidc_issuer_enabled"></a> [oidc\_issuer\_enabled](#input\_oidc\_issuer\_enabled) | (Optional) Enable or Disable the OIDC issuer URL | `bool` | `false` | no |
| <a name="input_oms_agent_monitoring_metrics_role_assignment_enabled"></a> [oms\_agent\_monitoring\_metrics\_role\_assignment\_enabled](#input\_oms\_agent\_monitoring\_metrics\_role\_assignment\_enabled) | Enabled oms agent monitoring metrics roles | `bool` | `true` | no |
| <a name="input_oms_agent_msi_auth_for_monitoring_enabled"></a> [oms\_agent\_msi\_auth\_for\_monitoring\_enabled](#input\_oms\_agent\_msi\_auth\_for\_monitoring\_enabled) | (Optional) Is managed identity authentication for monitoring enabled? Default false | `bool` | `false` | no |
| <a name="input_outbound_ip_address_ids"></a> [outbound\_ip\_address\_ids](#input\_outbound\_ip\_address\_ids) | The ID of the Public IP Addresses which should be used for outbound communication for the cluster load balancer. | `list(string)` | `[]` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | (Optional) Provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) Resource group name. | `string` | n/a | yes |
| <a name="input_sec_log_analytics_workspace_id"></a> [sec\_log\_analytics\_workspace\_id](#input\_sec\_log\_analytics\_workspace\_id) | Log analytics workspace security (it should be in a different subscription). | `string` | `null` | no |
| <a name="input_sec_storage_id"></a> [sec\_storage\_id](#input\_sec\_storage\_id) | Storage Account security (it should be in a different subscription). | `string` | `null` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | (Optional) The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid (which includes the Uptime SLA) | `string` | `"Free"` | no |
| <a name="input_storage_profile_blob_driver_enabled"></a> [storage\_profile\_blob\_driver\_enabled](#input\_storage\_profile\_blob\_driver\_enabled) | (Optional) Is the Blob CSI driver enabled? Defaults to false | `bool` | `false` | no |
| <a name="input_storage_profile_disk_driver_enabled"></a> [storage\_profile\_disk\_driver\_enabled](#input\_storage\_profile\_disk\_driver\_enabled) | (Optional) Is the Disk CSI driver enabled? Defaults to true | `bool` | `true` | no |
| <a name="input_storage_profile_disk_driver_version"></a> [storage\_profile\_disk\_driver\_version](#input\_storage\_profile\_disk\_driver\_version) | (Optional) Disk CSI Driver version to be used. Possible values are v1 and v2. Defaults to v1 | `string` | `"v1"` | no |
| <a name="input_storage_profile_file_driver_enabled"></a> [storage\_profile\_file\_driver\_enabled](#input\_storage\_profile\_file\_driver\_enabled) | (Optional) Is the File CSI driver enabled? Defaults to true | `bool` | `true` | no |
| <a name="input_storage_profile_snapshot_controller_enabled"></a> [storage\_profile\_snapshot\_controller\_enabled](#input\_storage\_profile\_snapshot\_controller\_enabled) | (Optional) Is the Snapshot Controller enabled? Defaults to true | `bool` | `true` | no |
| <a name="input_system_node_pool_availability_zones"></a> [system\_node\_pool\_availability\_zones](#input\_system\_node\_pool\_availability\_zones) | (Optional) List of availability zones for system node pool | `list(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_system_node_pool_enable_host_encryption"></a> [system\_node\_pool\_enable\_host\_encryption](#input\_system\_node\_pool\_enable\_host\_encryption) | (Optional) Should the nodes in the Default Node Pool have host encryption enabled? Defaults to true. | `bool` | `true` | no |
| <a name="input_system_node_pool_max_pods"></a> [system\_node\_pool\_max\_pods](#input\_system\_node\_pool\_max\_pods) | (Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created. | `number` | `250` | no |
| <a name="input_system_node_pool_name"></a> [system\_node\_pool\_name](#input\_system\_node\_pool\_name) | (Required) The name which should be used for the default Kubernetes Node Pool. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_system_node_pool_node_count_max"></a> [system\_node\_pool\_node\_count\_max](#input\_system\_node\_pool\_node\_count\_max) | (Required) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000. | `number` | n/a | yes |
| <a name="input_system_node_pool_node_count_min"></a> [system\_node\_pool\_node\_count\_min](#input\_system\_node\_pool\_node\_count\_min) | (Required) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000. | `number` | n/a | yes |
| <a name="input_system_node_pool_node_labels"></a> [system\_node\_pool\_node\_labels](#input\_system\_node\_pool\_node\_labels) | (Optional) A map of Kubernetes labels which should be applied to nodes in the Default Node Pool. Changing this forces a new resource to be created. | `map(any)` | `{}` | no |
| <a name="input_system_node_pool_only_critical_addons_enabled"></a> [system\_node\_pool\_only\_critical\_addons\_enabled](#input\_system\_node\_pool\_only\_critical\_addons\_enabled) | (Optional) Enabling this option will taint default node pool with CriticalAddonsOnly=true:NoSchedule taint. Changing this forces a new resource to be created. | `bool` | `true` | no |
| <a name="input_system_node_pool_os_disk_size_gb"></a> [system\_node\_pool\_os\_disk\_size\_gb](#input\_system\_node\_pool\_os\_disk\_size\_gb) | (Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created. | `number` | n/a | yes |
| <a name="input_system_node_pool_os_disk_type"></a> [system\_node\_pool\_os\_disk\_type](#input\_system\_node\_pool\_os\_disk\_type) | (Optional) The type of disk which should be used for the Operating System. Possible values are Ephemeral and Managed. Defaults to Managed. | `string` | `"Ephemeral"` | no |
| <a name="input_system_node_pool_tags"></a> [system\_node\_pool\_tags](#input\_system\_node\_pool\_tags) | (Optional) A mapping of tags to assign to the Node Pool. | `map(any)` | `{}` | no |
| <a name="input_system_node_pool_ultra_ssd_enabled"></a> [system\_node\_pool\_ultra\_ssd\_enabled](#input\_system\_node\_pool\_ultra\_ssd\_enabled) | (Optional) Used to specify whether the UltraSSD is enabled in the Default Node Pool. Defaults to false. | `bool` | `false` | no |
| <a name="input_system_node_pool_upgrade_settings_drain_timeout_in_minutes"></a> [system\_node\_pool\_upgrade\_settings\_drain\_timeout\_in\_minutes](#input\_system\_node\_pool\_upgrade\_settings\_drain\_timeout\_in\_minutes) | (Optional) The amount of time in minutes to wait on eviction of pods and graceful termination per node. This eviction wait time honors pod disruption budgets for upgrades. If this time is exceeded, the upgrade fails. Unsetting this after configuring it will force a new resource to be created. | `string` | `30` | no |
| <a name="input_system_node_pool_vm_size"></a> [system\_node\_pool\_vm\_size](#input\_system\_node\_pool\_vm\_size) | (Required) The size of the Virtual Machine, such as Standard\_B4ms or Standard\_D4s\_vX. See https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/134840344/Best+practice+su+prodotti | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_upgrade_settings_max_surge"></a> [upgrade\_settings\_max\_surge](#input\_upgrade\_settings\_max\_surge) | The maximum number or percentage of nodes which will be added to the Node Pool size during an upgrade. | `string` | `"33%"` | no |
| <a name="input_user_node_pool_availability_zones"></a> [user\_node\_pool\_availability\_zones](#input\_user\_node\_pool\_availability\_zones) | (Optional) List of availability zones for user node pool | `list(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_user_node_pool_enable_host_encryption"></a> [user\_node\_pool\_enable\_host\_encryption](#input\_user\_node\_pool\_enable\_host\_encryption) | (Optional) Should the nodes in the Default Node Pool have host encryption enabled? Defaults to true. | `bool` | `false` | no |
| <a name="input_user_node_pool_enabled"></a> [user\_node\_pool\_enabled](#input\_user\_node\_pool\_enabled) | Is user node pool enabled? | `bool` | `false` | no |
| <a name="input_user_node_pool_max_pods"></a> [user\_node\_pool\_max\_pods](#input\_user\_node\_pool\_max\_pods) | (Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created. | `number` | `250` | no |
| <a name="input_user_node_pool_name"></a> [user\_node\_pool\_name](#input\_user\_node\_pool\_name) | (Required) The name which should be used for the default Kubernetes Node Pool. Changing this forces a new resource to be created. | `string` | `""` | no |
| <a name="input_user_node_pool_node_count_max"></a> [user\_node\_pool\_node\_count\_max](#input\_user\_node\_pool\_node\_count\_max) | (Required) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000. | `number` | `0` | no |
| <a name="input_user_node_pool_node_count_min"></a> [user\_node\_pool\_node\_count\_min](#input\_user\_node\_pool\_node\_count\_min) | (Required) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000. | `number` | `0` | no |
| <a name="input_user_node_pool_node_labels"></a> [user\_node\_pool\_node\_labels](#input\_user\_node\_pool\_node\_labels) | (Optional) A map of Kubernetes labels which should be applied to nodes in the Default Node Pool. Changing this forces a new resource to be created. | `map(any)` | `{}` | no |
| <a name="input_user_node_pool_node_taints"></a> [user\_node\_pool\_node\_taints](#input\_user\_node\_pool\_node\_taints) | (Optional) A list of Kubernetes taints which should be applied to nodes in the agent pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created. | `list(string)` | `[]` | no |
| <a name="input_user_node_pool_os_disk_size_gb"></a> [user\_node\_pool\_os\_disk\_size\_gb](#input\_user\_node\_pool\_os\_disk\_size\_gb) | (Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created. | `number` | `0` | no |
| <a name="input_user_node_pool_os_disk_type"></a> [user\_node\_pool\_os\_disk\_type](#input\_user\_node\_pool\_os\_disk\_type) | (Optional) The type of disk which should be used for the Operating System. Possible values are Ephemeral and Managed. Defaults to Managed. | `string` | `"Ephemeral"` | no |
| <a name="input_user_node_pool_tags"></a> [user\_node\_pool\_tags](#input\_user\_node\_pool\_tags) | (Optional) A mapping of tags to assign to the Node Pool. | `map(any)` | `{}` | no |
| <a name="input_user_node_pool_ultra_ssd_enabled"></a> [user\_node\_pool\_ultra\_ssd\_enabled](#input\_user\_node\_pool\_ultra\_ssd\_enabled) | (Optional) Used to specify whether the UltraSSD is enabled in the Default Node Pool. Defaults to false. | `bool` | `false` | no |
| <a name="input_user_node_pool_upgrade_settings_drain_timeout_in_minutes"></a> [user\_node\_pool\_upgrade\_settings\_drain\_timeout\_in\_minutes](#input\_user\_node\_pool\_upgrade\_settings\_drain\_timeout\_in\_minutes) | (Optional) The amount of time in minutes to wait on eviction of pods and graceful termination per node. This eviction wait time honors pod disruption budgets for upgrades. If this time is exceeded, the upgrade fails. Unsetting this after configuring it will force a new resource to be created. | `string` | `30` | no |
| <a name="input_user_node_pool_vm_size"></a> [user\_node\_pool\_vm\_size](#input\_user\_node\_pool\_vm\_size) | (Required) The size of the Virtual Machine, such as Standard\_B4ms or Standard\_D4s\_vX. See https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/134840344/Best+practice+su+prodotti | `string` | `""` | no |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | (Required) Virtual network id, where the k8s cluster is deployed. | `string` | n/a | yes |
| <a name="input_vnet_subnet_id"></a> [vnet\_subnet\_id](#input\_vnet\_subnet\_id) | (Optional) The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_vnet_user_subnet_id"></a> [vnet\_user\_subnet\_id](#input\_vnet\_user\_subnet\_id) | (Optional) The ID of a Subnet where the Kubernetes User Node Pool should exist. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_workload_identity_enabled"></a> [workload\_identity\_enabled](#input\_workload\_identity\_enabled) | (Optional) Specifies whether Azure AD Workload Identity should be enabled for the Cluster. Defaults to false. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_resource_group_name"></a> [aks\_resource\_group\_name](#output\_aks\_resource\_group\_name) | AKS resource group name where the aks was installed |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | The FQDN of the Azure Kubernetes Managed Cluster. |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id) | The Principal ID associated with this Managed Service Identity. |
| <a name="output_kubelet_identity_id"></a> [kubelet\_identity\_id](#output\_kubelet\_identity\_id) | The Object ID of the user-defined Managed Identity assigned to the Kubelets.If not specified a Managed Identity is created automatically. Changing this forces a new resource to be created. |
| <a name="output_managed_private_dns_zone_name"></a> [managed\_private\_dns\_zone\_name](#output\_managed\_private\_dns\_zone\_name) | The managed private dns zone name for the Kubernetes Cluster when private link has been enabled. Derived from private\_fqdn |
| <a name="output_managed_resource_group_id"></a> [managed\_resource\_group\_id](#output\_managed\_resource\_group\_id) | The ID of the Resource Group containing the resources for this Managed Kubernetes Cluster. |
| <a name="output_managed_resource_group_name"></a> [managed\_resource\_group\_name](#output\_managed\_resource\_group\_name) | The auto-generated Resource Group which contains the resources for this Managed Kubernetes Cluster. |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_private_fqdn"></a> [private\_fqdn](#output\_private\_fqdn) | The FQDN for the Kubernetes Cluster when private link has been enabled, which is only resolvable inside the Virtual Network used by the Kubernetes Cluster. |
<!-- END_TF_DOCS -->
