variable "servicebus_namespace_id" {
  type        = string
  description = "The ID of the Service Bus Namespace where the topics will be created."
  nullable    = false
}

variable "servicebus_topics" {
  description = "A list of Service Bus Topics to add to input namespace"
  # see azurerm_servicebus_topic for details on Service Bus topic parameters
  type = list(object({
    name                                    = string
    status                                  = optional(string)
    auto_delete_on_idle                     = optional(string)
    default_message_ttl                     = optional(string)
    duplicate_detection_history_time_window = optional(string)
    batched_operations_enabled              = optional(bool)
    express_enabled                         = optional(bool)
    partitioning_enabled                    = optional(bool)
    max_message_size_in_kilobytes           = optional(number)
    max_size_in_megabytes                   = optional(number)
    requires_duplicate_detection            = optional(bool)
    support_ordering                        = optional(bool)

    subscriptions = optional(list(object({
      name                                      = string
      max_delivery_count                        = number
      auto_delete_on_idle                       = optional(string)
      default_message_ttl                       = optional(string)
      lock_duration                             = optional(string)
      dead_lettering_on_message_expiration      = optional(bool)
      dead_lettering_on_filter_evaluation_error = optional(bool)
      batched_operations_enabled                = optional(bool)
      requires_session                          = optional(bool)
      forward_to                                = optional(string)
      forward_dead_lettered_messages_to         = optional(string)
      status                                    = optional(string)
      client_scoped_subscription_enabled        = optional(bool)
      client_scoped_subscription = optional(object({
        client_id                               = optional(string)
        is_client_scoped_subscription_shareable = optional(bool)
        is_client_scoped_subscription_durable   = optional(bool)
      }))
      rules = optional(list(object({
        name        = string
        filter_type = string
        sql_filter  = optional(string)
        action      = optional(string)
        correlation_filter = optional(object({
          content_type        = optional(string)
          correlation_id      = optional(string)
          label               = optional(string)
          message_id          = optional(string)
          reply_to            = optional(string)
          reply_to_session_id = optional(string)
          session_id          = optional(string)
          to                  = optional(string)
          properties          = optional(map(string), {})
        }))
      })), [])
    })), [])
    # see azurerm_servicebus_topic_authorization_rule for details on the keys object structure
    keys = list(object({
      name   = string
      listen = optional(bool)
      send   = optional(bool)
      manage = optional(bool)
    }))
  }))
  default = []

}
