variable "servicebus_namespace_id" {
  type        = string
  description = "The ID of the Service Bus Namespace where the queues will be created."
  nullable    = false
}

variable "servicebus_queues" {
  description = "A list of Service Bus Queues to add to input namespace"
  type = list(object({
    name                                    = string                     #(Required) The service bus queue name
    auto_delete_on_idle                     = optional(string)           #(Optional) The ISO 8601 timespan duration of the idle interval after which the Queue is automatically deleted, minimum of 5 minutes
    batched_operations_enabled              = optional(bool, true)       #(Optional) Whether server-side batched operations are enabled, default true
    dead_lettering_on_message_expiration    = optional(bool, false)      #(Optional) Whether the Queue has dead letter support when a message expires, default false
    default_message_ttl                     = optional(string)           #(Optional) The ISO 8601 timespan duration of the default TTL of messages sent to this queue
    duplicate_detection_history_time_window = optional(string, "PT10M")  #(Optional) The ISO 8601 timespan duration during which duplicates can be detected, default PT10M
    express_enabled                         = optional(bool, false)      #(Optional) Whether Express Entities are enabled, default false
    forward_dead_lettered_messages_to       = optional(string)           #(Optional) The name of a Queue or Topic to automatically forward dead lettered messages to
    forward_to                              = optional(string)           #(Optional) The name of a Queue or Topic to automatically forward messages to
    lock_duration                           = optional(string, "PT1M")   #(Optional) The ISO 8601 timespan duration of a peek-lock, default PT1M
    max_delivery_count                      = optional(number, 10)       #(Optional) Number of times a message is delivered before it is automatically dead lettered, default 10
    max_message_size_in_kilobytes           = optional(number)           #(Optional) Maximum size of a message allowed on the queue for Premium SKU
    max_size_in_megabytes                   = optional(number)           #(Optional) Size of memory allocated for the queue
    partitioning_enabled                    = optional(bool, false)      #(Optional) Whether the queue is partitioned across multiple message brokers, default false for Basic and Standard
    requires_duplicate_detection            = optional(bool, false)      #(Optional) Whether the Queue requires duplicate detection, default false
    requires_session                        = optional(bool, false)      #(Optional) Whether the Queue requires sessions, default false
    status                                  = optional(string, "Active") #(Optional) The status of the Queue, default Active
    keys = list(object({
      name   = string                #(Required) The name of the authorization key - changing it will cause resource to be recreated
      listen = optional(bool, false) #(Optional) Whether the key has listen permissions, default false
      send   = optional(bool, false) #(Optional) Whether the key has send permissions, default false
      manage = optional(bool, false) #(Optional) Whether the key has manage permissions, default false. When this property is true - both listen and send must be too.
    }))
  }))
  default = []

  validation {
    condition = alltrue(flatten([
      for q in var.servicebus_queues : [
        for k in q.keys : !k.manage || (k.listen && k.send)
      ]
    ]))
    error_message = "If a queue authorization key sets manage = true, it must also set listen = true and send = true."
  }

  validation {
    condition = alltrue(flatten([
      for q in var.servicebus_queues : [
        for k in q.keys : k.listen || k.send
      ]
    ]))
    error_message = "Each queue authorization key must have at least one permission (listen or send) set to true."
  }

  validation {
    condition = alltrue([
      for q in var.servicebus_queues :
      q.status == null || contains([
        "Active",
        "Creating",
        "Deleting",
        "Disabled",
        "ReceiveDisabled",
        "Renaming",
        "SendDisabled",
        "Unknown",
      ], q.status)
    ])
    error_message = "Each queue status must be one of: Active, Creating, Deleting, Disabled, ReceiveDisabled, Renaming, SendDisabled, or Unknown."
  }
}
