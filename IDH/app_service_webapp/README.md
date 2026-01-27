# AppService

This module allows the creation of an App service function main slot and the staging slot if needed, with the required autoscale settings

## IDH resources available
[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module


## How to use

```hcl
module "metabase_app_service" {
  source              = "./.terraform/modules/__v4__/IDH/app_service_webapp"
  env                 = var.env
  idh_resource_tier   = var.metabase_plan_idh_tier
  location            = var.location
  name                = "${local.project}-metabase-webapp"
  product_name        = var.prefix
  resource_group_name = azurerm_resource_group.metabase_rg.name

  app_service_plan_name = "${local.project}-metabase-plan"
  app_settings = {
    # my application env variables
    MB_DB_USER           = module.secret_core.values["metabase-db-admin-login"].value
    MB_DB_PASS           = module.secret_core.values["metabase-db-admin-password"].value
    MB_DB_CONNECTION_URI = "jdbc:postgresql://${module.metabase_postgres_db.fqdn}:5432/metabase?ssl=true&sslmode=require"
  }
  docker_image        = "metabase/metabase"
  docker_image_tag    = "latest"
  docker_registry_url = "https://index.docker.io"
  tags                = module.tag_config.tags
  
  # which subnet is allowed to reach this app service
  allowed_subnet_ids = [data.azurerm_subnet.vpn_subnet.id]

  private_endpoint_dns_zone_id = data.azurerm_private_dns_zone.azurewebsites.id
  
  embedded_subnet = {
    enabled      = true
    vnet_name    = local.spoke_compute_vnet_name
    vnet_rg_name = local.spoke_compute_vnet_resource_group_name
  }

  embedded_nsg_configuration = {
    source_address_prefixes      = ["*"]
    source_address_prefixes_name = "All"
    target_ports                 = ["*"]
    protocol                     = "Tcp"
  }
  
  autoscale_settings = {
    max_capacity                  = 3
    scale_up_requests_threshold   = 250
    scale_down_requests_threshold = 150
  }

  always_on  = true
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
| <a name="module_main_slot"></a> [main\_slot](#module\_main\_slot) | ../../app_service | n/a |
| <a name="module_private_endpoint_snet"></a> [private\_endpoint\_snet](#module\_private\_endpoint\_snet) | ../subnet | n/a |
| <a name="module_staging_slot"></a> [staging\_slot](#module\_staging\_slot) | ../../app_service_slot | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_autoscale_setting.autoscale_settings](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |
| [azurerm_private_endpoint.main_slot_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.staging_slot_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | (Optional) List of ips allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_allowed_service_tags"></a> [allowed\_service\_tags](#input\_allowed\_service\_tags) | (Optional) List of service tags allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_allowed_subnet_ids"></a> [allowed\_subnet\_ids](#input\_allowed\_subnet\_ids) | (Optional) List of subnet allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_always_on"></a> [always\_on](#input\_always\_on) | (Optional) Should the app be loaded at all times? Defaults to false. | `bool` | `false` | no |
| <a name="input_app_service_plan_id"></a> [app\_service\_plan\_id](#input\_app\_service\_plan\_id) | (Optional) If External. Specifies the id of the App Service Plan component. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_app_service_plan_name"></a> [app\_service\_plan\_name](#input\_app\_service\_plan\_name) | (Required) Specifies the name of the App Service Plan component. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | n/a | `map(string)` | `{}` | no |
| <a name="input_auto_heal_enabled"></a> [auto\_heal\_enabled](#input\_auto\_heal\_enabled) | (Optional) True to enable the auto heal on the app service | `bool` | `false` | no |
| <a name="input_auto_heal_settings"></a> [auto\_heal\_settings](#input\_auto\_heal\_settings) | (Optional) Auto heal settings | <pre>object({<br/>    startup_time           = string<br/>    slow_requests_count    = number<br/>    slow_requests_interval = string<br/>    slow_requests_time     = string<br/>  })</pre> | `null` | no |
| <a name="input_autoscale_settings"></a> [autoscale\_settings](#input\_autoscale\_settings) | (Optional) Autoscale configuration | <pre>object({<br/>    max_capacity                       = number                 # maximum capacity for this app service<br/>    scale_up_requests_threshold        = optional(number, null) # request count threshold which triggers scale up<br/>    scale_down_requests_threshold      = optional(number, null) # request count threshold which triggers scale down<br/>    scale_up_response_time_threshold   = optional(number, null) # response time threshold which triggers scale up<br/>    scale_down_response_time_threshold = optional(number, null) # response time threshold which triggers scale down<br/>    scale_up_cpu_threshold             = optional(number, null) # cpu threshold which triggers scale up<br/>    scale_down_cpu_threshold           = optional(number, null) # cpu threshold which triggers scale down<br/>  })</pre> | `null` | no |
| <a name="input_client_affinity_enabled"></a> [client\_affinity\_enabled](#input\_client\_affinity\_enabled) | (Optional) Should the App Service send session affinity cookies, which route client requests in the same session to the same instance? Defaults to false. | `bool` | `false` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Framework choice | `string` | `null` | no |
| <a name="input_docker_image_tag"></a> [docker\_image\_tag](#input\_docker\_image\_tag) | n/a | `string` | `null` | no |
| <a name="input_docker_registry_password"></a> [docker\_registry\_password](#input\_docker\_registry\_password) | n/a | `string` | `null` | no |
| <a name="input_docker_registry_url"></a> [docker\_registry\_url](#input\_docker\_registry\_url) | n/a | `string` | `null` | no |
| <a name="input_docker_registry_username"></a> [docker\_registry\_username](#input\_docker\_registry\_username) | n/a | `string` | `null` | no |
| <a name="input_dotnet_version"></a> [dotnet\_version](#input\_dotnet\_version) | n/a | `string` | `null` | no |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) NSG configuration | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string # short name for source_address_prefixes<br/>    target_ports                 = list(string)<br/>    protocol                     = string<br/>  })</pre> | <pre>{<br/>  "protocol": "*",<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All",<br/>  "target_ports": [<br/>    "*"<br/>  ]<br/>}</pre> | no |
| <a name="input_embedded_subnet"></a> [embedded\_subnet](#input\_embedded\_subnet) | (Optional) Configuration for creating an embedded Subnet for the Cosmos private endpoint. When enabled, 'private\_endpoint\_subnet\_id' must be null. | <pre>object({<br/>    enabled      = bool<br/>    vnet_name    = optional(string, null)<br/>    vnet_rg_name = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_ftps_state"></a> [ftps\_state](#input\_ftps\_state) | (Optional) Enable FTPS connection ( Default: Disabled ) | `string` | `"Disabled"` | no |
| <a name="input_go_version"></a> [go\_version](#input\_go\_version) | n/a | `string` | `null` | no |
| <a name="input_health_check_maxpingfailures"></a> [health\_check\_maxpingfailures](#input\_health\_check\_maxpingfailures) | Max ping failures allowed | `number` | `null` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | (Optional) The health check path to be pinged by App Service. | `string` | `null` | no |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name of IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_java_server"></a> [java\_server](#input\_java\_server) | n/a | `string` | `null` | no |
| <a name="input_java_server_version"></a> [java\_server\_version](#input\_java\_server\_version) | n/a | `string` | `null` | no |
| <a name="input_java_version"></a> [java\_version](#input\_java\_version) | n/a | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | App service name, used as prefix in resource names | `string` | n/a | yes |
| <a name="input_node_version"></a> [node\_version](#input\_node\_version) | n/a | `string` | `null` | no |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_php_version"></a> [php\_version](#input\_php\_version) | n/a | `string` | `null` | no |
| <a name="input_plan_type"></a> [plan\_type](#input\_plan\_type) | (Optional) Create internal plan or use your own external. (Default: 'internal') | `string` | `"internal"` | no |
| <a name="input_private_endpoint_dns_zone_id"></a> [private\_endpoint\_dns\_zone\_id](#input\_private\_endpoint\_dns\_zone\_id) | (Optional) Private DNS Zone ID to link to the private endpoint | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | (Deprecated) Subnet id where to save the private endpoint. Use 'embedded\_subnet' instead | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) prefix used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | n/a | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group | `string` | n/a | yes |
| <a name="input_ruby_version"></a> [ruby\_version](#input\_ruby\_version) | n/a | `string` | `null` | no |
| <a name="input_sticky_settings"></a> [sticky\_settings](#input\_sticky\_settings) | (Optional) A list of app\_setting names that the Linux Function App will not swap between Slots when a swap operation is triggered | `list(string)` | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | (Deprecated) Subnet id wether you want to integrate the app service to a subnet.  Use 'embedded\_subnet' instead | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscale_settings_id"></a> [autoscale\_settings\_id](#output\_autoscale\_settings\_id) | The ID of the autoscale settings. |
| <a name="output_custom_domain_verification_id"></a> [custom\_domain\_verification\_id](#output\_custom\_domain\_verification\_id) | The custom domain verification ID of the main App Service slot. |
| <a name="output_default_site_hostname"></a> [default\_site\_hostname](#output\_default\_site\_hostname) | The default site hostname of the main App Service slot. |
| <a name="output_egress_snet_id"></a> [egress\_snet\_id](#output\_egress\_snet\_id) | The ID of the subnet used for egress traffic. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the main App Service slot. |
| <a name="output_idh_resource_configuration"></a> [idh\_resource\_configuration](#output\_idh\_resource\_configuration) | The IDH resource configuration object. |
| <a name="output_name"></a> [name](#output\_name) | The name of the main App Service slot. |
| <a name="output_plan_id"></a> [plan\_id](#output\_plan\_id) | The ID of the App Service Plan. |
| <a name="output_plan_name"></a> [plan\_name](#output\_plan\_name) | The name of the App Service Plan. |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | The principal ID of the system-assigned identity for the main App Service slot. |
| <a name="output_private_endpoint_main_slot"></a> [private\_endpoint\_main\_slot](#output\_private\_endpoint\_main\_slot) | The private endpoint resource of the main App Service slot. |
| <a name="output_private_endpoint_snet_id"></a> [private\_endpoint\_snet\_id](#output\_private\_endpoint\_snet\_id) | The ID of the subnet used for the private endpoint. |
| <a name="output_private_endpoint_staging_slot"></a> [private\_endpoint\_staging\_slot](#output\_private\_endpoint\_staging\_slot) | The private endpoint resource of the staging App Service slot. |
| <a name="output_staging_default_site_hostname"></a> [staging\_default\_site\_hostname](#output\_staging\_default\_site\_hostname) | The default site hostname of the staging App Service slot. |
| <a name="output_staging_id"></a> [staging\_id](#output\_staging\_id) | The ID of the staging App Service slot. |
| <a name="output_staging_name"></a> [staging\_name](#output\_staging\_name) | The name of the staging App Service slot. |
| <a name="output_staging_principal_id"></a> [staging\_principal\_id](#output\_staging\_principal\_id) | The principal ID of the system-assigned identity for the staging App Service slot. |
<!-- END_TF_DOCS -->
