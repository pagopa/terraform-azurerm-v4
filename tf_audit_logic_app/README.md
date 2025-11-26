# Terraform audit logic app

This module creates a logic app that monitors the terraform apply audit logs saved in the given container and sends alerts via slack
  
## How to use it

```hcl
module "tf_audit_logic_app" {
  source = "./.terraform/modules/__v4__/tf_audit_logic_app"

  location = var.location
  prefix = var.prefix
  resource_group_name = azurerm_resource_group.storage_rg.name
  slack_webhook_url = "<my_slack_webhook_url>"
  storage_account_settings = {
    name       = "<audit_storage_account_name>"
    table_name = "<audit_storage_account_table_name>"
    access_key = "<audit_storage_account_access_key>"
  }
  tags = var.tags
  trigger = {
    interval  = 5
    frequency = "Minute"
  }

}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_api_connection.storage_account_api_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_connection) | resource |
| [azurerm_logic_app_action_custom.elaborate_entity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom) | resource |
| [azurerm_logic_app_action_custom.get_entities](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom) | resource |
| [azurerm_logic_app_trigger_recurrence.trigger](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_trigger_recurrence) | resource |
| [azurerm_logic_app_workflow.workflow](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_workflow) | resource |
| [azurerm_managed_api.storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/managed_api) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | (Required) Resource location | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name for dedicated resource names | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | (Required) Prefix for dedicated resource names | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) Name of the resource group in which the function and its related components are created | `string` | n/a | yes |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | (Required) Slack webhook URL for notifications | `string` | n/a | yes |
| <a name="input_storage_account_settings"></a> [storage\_account\_settings](#input\_storage\_account\_settings) | (Required) Storage account settings for the Logic App | <pre>object({<br/>    name       = string<br/>    table_name = string<br/>    access_key = string<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_trigger"></a> [trigger](#input\_trigger) | (required) Trigger configuration for the Logic App | <pre>object({<br/>    interval  = number<br/>    frequency = string<br/>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
