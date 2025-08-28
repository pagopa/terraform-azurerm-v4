# AppService

This module allows the creation of an App service main function slot and the staging slot if needed, with the required autoscale settings

## IDH resources available
[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module


## How to use

```hcl
module "app_service" {
  source = "./.terraform/modules/__v4__/IDH/app_service"

  env = var.env
  idh_resource_tier = "standard"
  location = var.location
  
  name = "myeventhub"
  prefix = var.prefix
  resource_group_name = azurerm_resource_group.evh_rg.name
  tags = var.tags

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
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_main_slot"></a> [main\_slot](#module\_main\_slot) | ../../app_service | n/a |
| <a name="module_staging_slot"></a> [staging\_slot](#module\_staging\_slot) | ../../app_service_slot | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_autoscale_setting.autoscale_settings](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | (Optional) List of ips allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_allowed_service_tags"></a> [allowed\_service\_tags](#input\_allowed\_service\_tags) | (Optional) List of service tags allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_allowed_subnet_ids"></a> [allowed\_subnet\_ids](#input\_allowed\_subnet\_ids) | (Optional) List of subnet allowed to call the appserver endpoint. | `list(string)` | `[]` | no |
| <a name="input_always_on"></a> [always\_on](#input\_always\_on) | (Optional) Should the app be loaded at all times? Defaults to false. | `bool` | `false` | no |
| <a name="input_app_service_plan_name"></a> [app\_service\_plan\_name](#input\_app\_service\_plan\_name) | (Optional) Specifies the name of the App Service Plan component. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | n/a | `map(string)` | `""` | no |
| <a name="input_auto_heal_enabled"></a> [auto\_heal\_enabled](#input\_auto\_heal\_enabled) | (Optional) True to enable the auto heal on the app service | `bool` | `false` | no |
| <a name="input_auto_heal_settings"></a> [auto\_heal\_settings](#input\_auto\_heal\_settings) | (Optional) Auto heal settings | <pre>object({<br/>    startup_time           = string<br/>    slow_requests_count    = number<br/>    slow_requests_interval = string<br/>    slow_requests_time     = string<br/>  })</pre> | `null` | no |
| <a name="input_autoscale_settings"></a> [autoscale\_settings](#input\_autoscale\_settings) | (Optional) Autoscale configuration | <pre>object({<br/>    max_capacity                       = number # maximum capacity for this app service<br/>    scale_up_requests_threshold        = number # request count threshold which triggers scale up<br/>    scale_down_requests_threshold      = number # request count threshold which triggers scale down<br/>    scale_up_response_time_threshold   = number # response time threshold which triggers scale up<br/>    scale_down_response_time_threshold = number # response time threshold which triggers scale down<br/>    scale_up_cpu_threshold             = number # cpu threshold which triggers scale up<br/>    scale_down_cpu_threshold           = number # cpu threshold which triggers scale down<br/>  })</pre> | `null` | no |
| <a name="input_client_affinity_enabled"></a> [client\_affinity\_enabled](#input\_client\_affinity\_enabled) | (Optional) Should the App Service send session affinity cookies, which route client requests in the same session to the same instance? Defaults to false. | `bool` | `false` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Framework choice | `string` | `null` | no |
| <a name="input_docker_image_tag"></a> [docker\_image\_tag](#input\_docker\_image\_tag) | n/a | `string` | `null` | no |
| <a name="input_dotnet_version"></a> [dotnet\_version](#input\_dotnet\_version) | n/a | `string` | `null` | no |
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
| <a name="input_name"></a> [name](#input\_name) | Eventhub namespace description. | `string` | n/a | yes |
| <a name="input_node_version"></a> [node\_version](#input\_node\_version) | n/a | `string` | `null` | no |
| <a name="input_php_version"></a> [php\_version](#input\_php\_version) | n/a | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) prefix used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | n/a | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group | `string` | n/a | yes |
| <a name="input_ruby_version"></a> [ruby\_version](#input\_ruby\_version) | n/a | `string` | `null` | no |
| <a name="input_sticky_settings"></a> [sticky\_settings](#input\_sticky\_settings) | (Optional) A list of app\_setting names that the Linux Function App will not swap between Slots when a swap operation is triggered | `list(string)` | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | (Optional) Subnet id wether you want to integrate the app service to a subnet. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
