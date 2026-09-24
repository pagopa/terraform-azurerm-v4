# Service Bus queues

This module creates one or more Azure Service Bus queues inside an existing Service Bus namespace, together with optional queue authorization rules for each queue.

## Examples

```hcl
module "servicebus_queues" {
  source = "./servicebus_queues"

  servicebus_namespace_id = azurerm_servicebus_namespace.example.id

  servicebus_queues = [
    {
      name                                 = "orders"
      default_message_ttl                  = "P14D"
      duplicate_detection_history_time_window = "PT10M"
      lock_duration                        = "PT1M"
      max_delivery_count                   = 10
      partitioning_enabled                 = false
      requires_duplicate_detection         = false
      requires_session                     = false
      status                               = "Active"
      keys = [
        {
          name   = "producer"
          listen = false
          send   = true
          manage = false
        },
        {
          name   = "consumer"
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

- The module expects an existing Service Bus namespace and creates only queues and queue-level authorization rules.
- Authorization rules follow the provider constraints: at least one permission must be enabled, and `manage = true` requires both `listen = true` and `send = true`.
- Defaults explicitly set in `variables.tf` mirror the defaults documented by the AzureRM provider where applicable.

## Troubleshooting

- If `terraform validate` fails on authorization rules, check that each key enables at least one between `listen` and `send`.
- If `manage = true` is set on a key, also set `listen = true` and `send = true`.
- If `forward_to` or `forward_dead_lettered_messages_to` is used, make sure the target entity exists in the same namespace.

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
| [azurerm_servicebus_queue.queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue) | resource |
| [azurerm_servicebus_queue_authorization_rule.queue_auth_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue_authorization_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_servicebus_namespace_id"></a> [servicebus\_namespace\_id](#input\_servicebus\_namespace\_id) | The ID of the Service Bus Namespace where the queues will be created. | `string` | n/a | yes |
| <a name="input_servicebus_queues"></a> [servicebus\_queues](#input\_servicebus\_queues) | A list of Service Bus Queues to add to input namespace | <pre>list(object({<br/>    name                                    = string                     #(Required) The service bus queue name<br/>    auto_delete_on_idle                     = optional(string)           #(Optional) The ISO 8601 timespan duration of the idle interval after which the Queue is automatically deleted, minimum of 5 minutes<br/>    batched_operations_enabled              = optional(bool, true)       #(Optional) Whether server-side batched operations are enabled, default true<br/>    dead_lettering_on_message_expiration    = optional(bool, false)      #(Optional) Whether the Queue has dead letter support when a message expires, default false<br/>    default_message_ttl                     = optional(string)           #(Optional) The ISO 8601 timespan duration of the default TTL of messages sent to this queue<br/>    duplicate_detection_history_time_window = optional(string, "PT10M")  #(Optional) The ISO 8601 timespan duration during which duplicates can be detected, default PT10M<br/>    express_enabled                         = optional(bool, false)      #(Optional) Whether Express Entities are enabled, default false<br/>    forward_dead_lettered_messages_to       = optional(string)           #(Optional) The name of a Queue or Topic to automatically forward dead lettered messages to<br/>    forward_to                              = optional(string)           #(Optional) The name of a Queue or Topic to automatically forward messages to<br/>    lock_duration                           = optional(string, "PT1M")   #(Optional) The ISO 8601 timespan duration of a peek-lock, default PT1M<br/>    max_delivery_count                      = optional(number, 10)       #(Optional) Number of times a message is delivered before it is automatically dead lettered, default 10<br/>    max_message_size_in_kilobytes           = optional(number)           #(Optional) Maximum size of a message allowed on the queue for Premium SKU<br/>    max_size_in_megabytes                   = optional(number)           #(Optional) Size of memory allocated for the queue<br/>    partitioning_enabled                    = optional(bool, false)      #(Optional) Whether the queue is partitioned across multiple message brokers, default false for Basic and Standard<br/>    requires_duplicate_detection            = optional(bool, false)      #(Optional) Whether the Queue requires duplicate detection, default false<br/>    requires_session                        = optional(bool, false)      #(Optional) Whether the Queue requires sessions, default false<br/>    status                                  = optional(string, "Active") #(Optional) The status of the Queue, default Active<br/>    keys = list(object({<br/>      name   = string                #(Required) The name of the authorization key - changing it will cause resource to be recreated<br/>      listen = optional(bool, false) #(Optional) Whether the key has listen permissions, default false<br/>      send   = optional(bool, false) #(Optional) Whether the key has send permissions, default false<br/>      manage = optional(bool, false) #(Optional) Whether the key has manage permissions, default false. When this property is true - both listen and send must be too.<br/>    }))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_queue_authorization_rules"></a> [queue\_authorization\_rules](#output\_queue\_authorization\_rules) | Map of Service Bus Queue authorization rules and their generated credentials. |
| <a name="output_queue_ids"></a> [queue\_ids](#output\_queue\_ids) | Map of Service Bus Queue names to their resource IDs. |
| <a name="output_queues"></a> [queues](#output\_queues) | Map of Service Bus Queue names to their main resource attributes. |
<!-- END_TF_DOCS -->