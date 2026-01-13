# AppService

This module allows the creation of an App service main function slot and the staging slot if needed, with the required autoscale settings

## IDH resources available
[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module


## How to use

```hcl

module "my_function" {
  source              = "./.terraform/modules/__v4__/IDH/app_service_function"
  env                 = var.env
  idh_resource_tier   = "basic"
  location            = var.location
  name                = "pagopa-d-function"
  product_name        = var.prefix
  resource_group_name = azurerm_resource_group.metabase_rg.name

  app_service_plan_name = "${local.project}-test-plan"
  app_settings = {
    PROPERTY_1           = "..."
    PROPERTY_2           = "..."
    PROPERTY_3           = "..."

  }
  docker_image        = "my_image/image_name"
  docker_image_tag    = "latest"
  docker_registry_url = "https://index.docker.io"
  subnet_id           = module.function_app_service_snet.subnet_id
  tags                = module.tag_config.tags

  allowed_subnet_ids = [data.azurerm_subnet.vpn_subnet.id]

  private_endpoint_dns_zone_id = data.azurerm_private_dns_zone.azurewebsites.id
  private_endpoint_subnet_id   = data.azurerm_subnet.private_endpoint_subnet.id

  application_insights_instrumentation_key = data.azurerm_application_insights.application_insights.instrumentation_key
  #optional
  internal_storage = {
    enable = true
    blobs_retention_days = 1
    containers = []
    private_dns_zone_blob_ids = []
    private_dns_zone_queue_ids = []
    private_dns_zone_table_ids = []
    private_endpoint_subnet_id = module.function_app_service_snet.id
    queues = []
  }
  autoscale_settings = {
    max_capacity                  = 3
    scale_up_requests_threshold   = 250
    scale_down_requests_threshold = 150

  }

  always_on = true
}

```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_egress_snet"></a> [egress\_snet](#module\_egress\_snet) | ../subnet | n/a |
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_main_slot"></a> [main\_slot](#module\_main\_slot) | ../../function_app | n/a |
| <a name="module_private_endpoint_snet"></a> [private\_endpoint\_snet](#module\_private\_endpoint\_snet) | ../subnet | n/a |
| <a name="module_reporting_analysis_function_slot_staging"></a> [reporting\_analysis\_function\_slot\_staging](#module\_reporting\_analysis\_function\_slot\_staging) | ../../function_app_slot | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_app_service_plan.function_service_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_plan) | resource |
| [azurerm_monitor_autoscale_setting.autoscale_settings](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |
| [azurerm_private_endpoint.main_slot_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.staging_slot_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action"></a> [action](#input\_action) | The ID of the Action Group and optional map of custom string properties to include with the post webhook operation. | <pre>set(object(<br/>    {<br/>      action_group_id    = string<br/>      webhook_properties = map(string)<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | (Optional) List of ips allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_allowed_service_tags"></a> [allowed\_service\_tags](#input\_allowed\_service\_tags) | (Optional) List of service tags allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_allowed_subnet_ids"></a> [allowed\_subnet\_ids](#input\_allowed\_subnet\_ids) | (Optional) List of subnet allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_always_on"></a> [always\_on](#input\_always\_on) | (Optional) Should the app be loaded at all times? Defaults to false. | `bool` | `false` | no |
| <a name="input_app_service_logs"></a> [app\_service\_logs](#input\_app\_service\_logs) | disk\_quota\_mb - (Optional) The amount of disk space to use for logs. Valid values are between 25 and 100. Defaults to 35. retention\_period\_days - (Optional) The retention period for logs in days. Valid values are between 0 and 99999.(never delete). | <pre>object({<br/>    disk_quota_mb         = number<br/>    retention_period_days = number<br/>  })</pre> | `null` | no |
| <a name="input_app_service_plan_name"></a> [app\_service\_plan\_name](#input\_app\_service\_plan\_name) | (Required) Specifies the name of the App Service Plan component. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | n/a | `map(string)` | `{}` | no |
| <a name="input_application_insights_instrumentation_key"></a> [application\_insights\_instrumentation\_key](#input\_application\_insights\_instrumentation\_key) | (Required) The Instrumentation Key of an Application Insights component. | `string` | n/a | yes |
| <a name="input_autoscale_settings"></a> [autoscale\_settings](#input\_autoscale\_settings) | (Optional) Autoscale configuration | <pre>object({<br/>    max_capacity                       = number                 # maximum capacity for this app service<br/>    scale_up_requests_threshold        = optional(number, null) # request count threshold which triggers scale up<br/>    scale_down_requests_threshold      = optional(number, null) # request count threshold which triggers scale down<br/>    scale_up_response_time_threshold   = optional(number, null) # response time threshold which triggers scale up<br/>    scale_down_response_time_threshold = optional(number, null) # response time threshold which triggers scale down<br/>    scale_up_cpu_threshold             = optional(number, null) # cpu threshold which triggers scale up<br/>    scale_down_cpu_threshold           = optional(number, null) # cpu threshold which triggers scale down<br/>  })</pre> | `null` | no |
| <a name="input_cors"></a> [cors](#input\_cors) | n/a | <pre>object({<br/>    allowed_origins = list(string) # A list of origins which should be able to make cross-origin calls. * can be used to allow all calls.<br/>  })</pre> | `null` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Framework choice | `string` | `null` | no |
| <a name="input_docker_image_tag"></a> [docker\_image\_tag](#input\_docker\_image\_tag) | n/a | `string` | `null` | no |
| <a name="input_docker_registry_password"></a> [docker\_registry\_password](#input\_docker\_registry\_password) | n/a | `string` | `null` | no |
| <a name="input_docker_registry_url"></a> [docker\_registry\_url](#input\_docker\_registry\_url) | n/a | `string` | `null` | no |
| <a name="input_docker_registry_username"></a> [docker\_registry\_username](#input\_docker\_registry\_username) | n/a | `string` | `null` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Specifies the domain of the Function App. | `string` | `null` | no |
| <a name="input_dotnet_version"></a> [dotnet\_version](#input\_dotnet\_version) | n/a | `string` | `null` | no |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) NSG configuration | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string # short name for source_address_prefixes<br/>    target_ports                 = list(string)<br/>    protocol                     = string<br/>  })</pre> | <pre>{<br/>  "protocol": "*",<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All",<br/>  "target_ports": [<br/>    "*"<br/>  ]<br/>}</pre> | no |
| <a name="input_embedded_subnet"></a> [embedded\_subnet](#input\_embedded\_subnet) | (Optional) Configuration for creating an embedded Subnet for the Cosmos private endpoint. When enabled, 'private\_endpoint\_subnet\_id' must be null. | <pre>object({<br/>    enabled      = bool<br/>    vnet_name    = optional(string, null)<br/>    vnet_rg_name = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_health_check_maxpingfailures"></a> [health\_check\_maxpingfailures](#input\_health\_check\_maxpingfailures) | Max ping failures allowed | `number` | `null` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | (Optional) The health check path to be pinged by App Service. | `string` | `null` | no |
| <a name="input_healthcheck_threshold"></a> [healthcheck\_threshold](#input\_healthcheck\_threshold) | The healthcheck threshold. If metric average is under this value, the alert will be triggered. Default is 50 | `number` | `50` | no |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name of IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_internal_storage"></a> [internal\_storage](#input\_internal\_storage) | n/a | <pre>object({<br/>    enable                     = bool<br/>    private_endpoint_subnet_id = string<br/>    private_dns_zone_blob_ids  = list(string)<br/>    private_dns_zone_queue_ids = list(string)<br/>    private_dns_zone_table_ids = list(string)<br/>    queues                     = list(string) # Queues names<br/>    containers                 = list(string) # Containers names<br/>    blobs_retention_days       = number<br/>  })</pre> | <pre>{<br/>  "blobs_retention_days": 1,<br/>  "containers": [],<br/>  "enable": false,<br/>  "private_dns_zone_blob_ids": [],<br/>  "private_dns_zone_queue_ids": [],<br/>  "private_dns_zone_table_ids": [],<br/>  "private_endpoint_subnet_id": "dummy",<br/>  "queues": []<br/>}</pre> | no |
| <a name="input_java_version"></a> [java\_version](#input\_java\_version) | n/a | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | App service name, used as prefix in resource names | `string` | n/a | yes |
| <a name="input_node_version"></a> [node\_version](#input\_node\_version) | n/a | `string` | `null` | no |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_powershell_core_version"></a> [powershell\_core\_version](#input\_powershell\_core\_version) | n/a | `string` | `null` | no |
| <a name="input_pre_warmed_instance_count"></a> [pre\_warmed\_instance\_count](#input\_pre\_warmed\_instance\_count) | The number of pre-warmed instances for this function app. Only affects apps on the Premium plan. | `number` | `1` | no |
| <a name="input_private_endpoint_dns_zone_id"></a> [private\_endpoint\_dns\_zone\_id](#input\_private\_endpoint\_dns\_zone\_id) | (Optional) Private DNS Zone ID to link to the private endpoint | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | (Deprecated) Subnet id where to save the private endpoint. Use 'embedded\_subnet instead' | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) prefix used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | n/a | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group | `string` | n/a | yes |
| <a name="input_sticky_app_setting_names"></a> [sticky\_app\_setting\_names](#input\_sticky\_app\_setting\_names) | (Optional) A list of app\_setting names that the Linux Function App will not swap between Slots when a swap operation is triggered | `list(string)` | `[]` | no |
| <a name="input_sticky_connection_string_names"></a> [sticky\_connection\_string\_names](#input\_sticky\_connection\_string\_names) | (Optional) A list of connection string names that the Linux Function App will not swap between Slots when a swap operation is triggered | `list(string)` | `null` | no |
| <a name="input_storage_account_durable_name"></a> [storage\_account\_durable\_name](#input\_storage\_account\_durable\_name) | Storage account name only used by the durable function. If null it will be 'computed' | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | (Deprecated) Subnet id wether you want to integrate the app service to a subnet. Use 'embedded\_subnet' instead | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `string` | `""` | no |
| <a name="input_use_custom_runtime"></a> [use\_custom\_runtime](#input\_use\_custom\_runtime) | n/a | `string` | `null` | no |
| <a name="input_use_dotnet_isolated_runtime"></a> [use\_dotnet\_isolated\_runtime](#input\_use\_dotnet\_isolated\_runtime) | n/a | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | n/a |
| <a name="output_default_key"></a> [default\_key](#output\_default\_key) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_master_key"></a> [master\_key](#output\_master\_key) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_primary_key"></a> [primary\_key](#output\_primary\_key) | n/a |
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | n/a |
| <a name="output_service_plan_id"></a> [service\_plan\_id](#output\_service\_plan\_id) | n/a |
| <a name="output_service_plan_name"></a> [service\_plan\_name](#output\_service\_plan\_name) | n/a |
<!-- END_TF_DOCS -->
