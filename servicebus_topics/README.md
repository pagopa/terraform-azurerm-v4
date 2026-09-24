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
| [azurerm_servicebus_topic.topic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic) | resource |
| [azurerm_servicebus_topic_authorization_rule.topic_auth_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic_authorization_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_servicebus_namespace_id"></a> [servicebus\_namespace\_id](#input\_servicebus\_namespace\_id) | The ID of the Service Bus Namespace where the topics will be created. | `string` | n/a | yes |
| <a name="input_servicebus_topics"></a> [servicebus\_topics](#input\_servicebus\_topics) | A list of Service Bus Topics to add to input namespace | <pre>list(object({<br/>    name                                    = string                                         #(Required) The service bus topic name<br/>    status                                  = optional(string, "Active")                     #(Optional) The status of the Topic, default Active<br/>    auto_delete_on_idle                     = optional(string, "P10675199DT2H48M5.4775807S") #(Optional) The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted, default P10675199DT2H48M5.4775807S<br/>    default_message_ttl                     = optional(string, "P10675199DT2H48M5.4775807S") #(Optional) The ISO 8601 timespan duration of the default TTL of messages sent to this topic, default P10675199DT2H48M5.4775807S<br/>    duplicate_detection_history_time_window = optional(string, "PT10M")                      #(Optional) The ISO 8601 timespan duration during which duplicates can be detected, default PT10M<br/>    batched_operations_enabled              = optional(bool)                                 #(Optional) Whether server-side batched operations are enabled<br/>    express_enabled                         = optional(bool)                                 #(Optional) Whether Express Entities are enabled<br/>    partitioning_enabled                    = optional(bool)                                 #(Optional) Whether the topic is partitioned across multiple message brokers<br/>    max_message_size_in_kilobytes           = optional(number, 256)                          #(Optional) Maximum size of a message allowed on the topic for Premium SKU, default 256<br/>    max_size_in_megabytes                   = optional(number, 5120)                         #(Optional) Size of memory allocated for the topic, default 5120<br/>    requires_duplicate_detection            = optional(bool, false)                          #(Optional) Whether the Topic requires duplicate detection, default false<br/>    support_ordering                        = optional(bool)                                 #(Optional) Whether the Topic supports ordering<br/>    keys = list(object({<br/>      name   = string                #(Required) The name of the authorization key - changing it will cause resource to be recreated<br/>      listen = optional(bool, false) #(Optional) Whether the key has listen permissions, default false<br/>      send   = optional(bool, false) #(Optional) Whether the key has send permissions, default false<br/>      manage = optional(bool, false) #(Optional) Whether the key has manage permissions, default false. When this property is true - both listen and send must be too.<br/>    }))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_topic_authorization_rules"></a> [topic\_authorization\_rules](#output\_topic\_authorization\_rules) | Map of Service Bus Topic authorization rules and their generated credentials. |
| <a name="output_topic_ids"></a> [topic\_ids](#output\_topic\_ids) | Map of Service Bus Topic names to their resource IDs. |
| <a name="output_topics"></a> [topics](#output\_topics) | Map of Service Bus Topic names to their main resource attributes. |
<!-- END_TF_DOCS -->