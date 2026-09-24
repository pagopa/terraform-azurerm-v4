variable "servicebus_namespace_id" {
  type        = string
  description = "The ID of the Service Bus Namespace where the topics will be created."
  nullable    = false
}

variable "servicebus_topics" {
  description = "A list of Service Bus Topics to add to input namespace"
  type = list(object({
    name                                    = string                                         #(Required) The service bus topic name
    status                                  = optional(string, "Active")                     #(Optional) The status of the Topic, default Active
    auto_delete_on_idle                     = optional(string, "P10675199DT2H48M5.4775807S") #(Optional) The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted, default P10675199DT2H48M5.4775807S
    default_message_ttl                     = optional(string, "P10675199DT2H48M5.4775807S") #(Optional) The ISO 8601 timespan duration of the default TTL of messages sent to this topic, default P10675199DT2H48M5.4775807S
    duplicate_detection_history_time_window = optional(string, "PT10M")                      #(Optional) The ISO 8601 timespan duration during which duplicates can be detected, default PT10M
    batched_operations_enabled              = optional(bool)                                 #(Optional) Whether server-side batched operations are enabled
    express_enabled                         = optional(bool)                                 #(Optional) Whether Express Entities are enabled
    partitioning_enabled                    = optional(bool)                                 #(Optional) Whether the topic is partitioned across multiple message brokers
    max_message_size_in_kilobytes           = optional(number, 256)                          #(Optional) Maximum size of a message allowed on the topic for Premium SKU, default 256
    max_size_in_megabytes                   = optional(number, 5120)                         #(Optional) Size of memory allocated for the topic, default 5120
    requires_duplicate_detection            = optional(bool, false)                          #(Optional) Whether the Topic requires duplicate detection, default false
    support_ordering                        = optional(bool)                                 #(Optional) Whether the Topic supports ordering
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
      for t in var.servicebus_topics : [
        for k in t.keys : !k.manage || (k.listen && k.send)
      ]
    ]))
    error_message = "If a topic authorization key sets manage = true, it must also set listen = true and send = true."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.servicebus_topics : [
        for k in t.keys : k.listen || k.send
      ]
    ]))
    error_message = "Each topic authorization key must have at least one permission (listen or send) set to true."
  }

  validation {
    condition = alltrue([
      for t in var.servicebus_topics :
      contains([
        "Active",
        "Disabled",
      ], t.status)
    ])
    error_message = "Each topic status must be one of: Active or Disabled."
  }
}
