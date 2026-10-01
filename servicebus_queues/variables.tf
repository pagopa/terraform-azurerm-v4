variable "servicebus_namespace_id" {
  type        = string
  description = "The ID of the Service Bus Namespace where the queues will be created."
  nullable    = false
}

variable "servicebus_queues" {
  description = "A list of Service Bus Queues to add to input namespace"
  # see azurerm_servicebus_queue for details on Service Bus queue parameters
  type = list(object({
    name                                    = string
    auto_delete_on_idle                     = optional(string)
    batched_operations_enabled              = optional(bool)
    dead_lettering_on_message_expiration    = optional(bool)
    default_message_ttl                     = optional(string)
    duplicate_detection_history_time_window = optional(string)
    express_enabled                         = optional(bool)
    forward_dead_lettered_messages_to       = optional(string)
    forward_to                              = optional(string)
    lock_duration                           = optional(string)
    max_delivery_count                      = optional(number)
    max_message_size_in_kilobytes           = optional(number)
    max_size_in_megabytes                   = optional(number)
    partitioning_enabled                    = optional(bool)
    requires_duplicate_detection            = optional(bool)
    requires_session                        = optional(bool)
    status                                  = optional(string)
    # see azurerm_servicebus_queue_authorization_rule for details on the keys object structure
    keys = list(object({
      name   = string
      listen = optional(bool)
      send   = optional(bool)
      manage = optional(bool)
    }))
  }))
  default = []

}
