# Service Bus topics

This module creates one or more Azure Service Bus topics inside an existing Service Bus namespace, together with optional topic authorization rules for each topic.

## Examples

```hcl
module "servicebus_topics" {
  source = "./servicebus_topics"

  servicebus_namespace_id = azurerm_servicebus_namespace.example.id

  servicebus_topics = [
    {
      name                         = "notifications"
      status                       = "Active"
      default_message_ttl          = "P14D"
      max_size_in_megabytes        = 5120
      requires_duplicate_detection = false
      support_ordering             = false
      keys = [
        {
          name   = "publisher"
          listen = false
          send   = true
          manage = false
        },
        {
          name   = "subscriber"
          listen = true
          send   = false
          manage = false
        }
      ]
    }
  ]
}
```

## Notes

- The module expects an existing Service Bus namespace and creates only topics and topic-level authorization rules.
- Topic `status` is validated against the values documented by the provider: `Active` and `Disabled`.
- Authorization rules follow the provider constraints: at least one permission must be enabled, and `manage = true` requires both `listen = true` and `send = true`.

## Troubleshooting

- If `terraform validate` fails on `status`, use only `Active` or `Disabled`.
- If `terraform validate` fails on authorization rules, check that each key enables at least one between `listen` and `send`.
- If `manage = true` is set on a key, also set `listen = true` and `send = true`.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_servicebus_topic.topics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic) | resource |
| [azurerm_servicebus_topic_authorization_rule.topic_auth_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic_authorization_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_servicebus_namespace_id"></a> [servicebus\_namespace\_id](#input\_servicebus\_namespace\_id) | The ID of the Service Bus Namespace where the topics will be created. | `string` | n/a | yes |
| <a name="input_servicebus_topics"></a> [servicebus\_topics](#input\_servicebus\_topics) | A list of Service Bus Topics to add to input namespace | <pre>list(object({<br/>    name                                    = string<br/>    status                                  = optional(string)<br/>    auto_delete_on_idle                     = optional(string)<br/>    default_message_ttl                     = optional(string)<br/>    duplicate_detection_history_time_window = optional(string)<br/>    batched_operations_enabled              = optional(bool)<br/>    express_enabled                         = optional(bool)<br/>    partitioning_enabled                    = optional(bool)<br/>    max_message_size_in_kilobytes           = optional(number)<br/>    max_size_in_megabytes                   = optional(number)<br/>    requires_duplicate_detection            = optional(bool)<br/>    support_ordering                        = optional(bool)<br/><br/>    subscriptions = optional(list(object({<br/>      name                                      = string<br/>      max_delivery_count                        = number<br/>      auto_delete_on_idle                       = optional(string)<br/>      default_message_ttl                       = optional(string)<br/>      lock_duration                             = optional(string)<br/>      dead_lettering_on_message_expiration      = optional(bool)<br/>      dead_lettering_on_filter_evaluation_error = optional(bool)<br/>      batched_operations_enabled                = optional(bool)<br/>      requires_session                          = optional(bool)<br/>      forward_to                                = optional(string)<br/>      forward_dead_lettered_messages_to         = optional(string)<br/>      status                                    = optional(string)<br/>      client_scoped_subscription_enabled        = optional(bool)<br/>      client_scoped_subscription = optional(object({<br/>        client_id                               = optional(string)<br/>        is_client_scoped_subscription_shareable = optional(bool)<br/>        is_client_scoped_subscription_durable   = optional(bool)<br/>      }))<br/>      rules = optional(list(object({<br/>        name        = string<br/>        filter_type = string<br/>        sql_filter  = optional(string)<br/>        action      = optional(string)<br/>        correlation_filter = optional(object({<br/>          content_type        = optional(string)<br/>          correlation_id      = optional(string)<br/>          label               = optional(string)<br/>          message_id          = optional(string)<br/>          reply_to            = optional(string)<br/>          reply_to_session_id = optional(string)<br/>          session_id          = optional(string)<br/>          to                  = optional(string)<br/>          properties          = optional(map(string), {})<br/>        }))<br/>      })), [])<br/>    })), [])<br/>    # see azurerm_servicebus_topic_authorization_rule for details on the keys object structure<br/>    keys = list(object({<br/>      name   = string<br/>      listen = optional(bool)<br/>      send   = optional(bool)<br/>      manage = optional(bool)<br/>    }))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_topic_authorization_rules"></a> [topic\_authorization\_rules](#output\_topic\_authorization\_rules) | Map of Service Bus Topic authorization rules and their generated credentials. |
| <a name="output_topic_ids"></a> [topic\_ids](#output\_topic\_ids) | Map of Service Bus Topic names to their resource IDs. |
| <a name="output_topics"></a> [topics](#output\_topics) | Map of Service Bus Topic names to their main resource attributes. |
<!-- END_TF_DOCS -->