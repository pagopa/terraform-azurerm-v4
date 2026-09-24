output "queue_ids" {
  description = "Map of Service Bus Queue names to their resource IDs."
  value       = { for name, queue in azurerm_servicebus_queue.queue : queue.name => queue.id }
}

output "queues" {
  description = "Map of Service Bus Queue names to their main resource attributes."
  value = {
    for name, queue in azurerm_servicebus_queue.queue : queue.name => {
      id                                      = queue.id
      name                                    = queue.name
      namespace_id                            = queue.namespace_id
      auto_delete_on_idle                     = queue.auto_delete_on_idle
      batched_operations_enabled              = queue.batched_operations_enabled
      dead_lettering_on_message_expiration    = queue.dead_lettering_on_message_expiration
      default_message_ttl                     = queue.default_message_ttl
      duplicate_detection_history_time_window = queue.duplicate_detection_history_time_window
      express_enabled                         = queue.express_enabled
      forward_dead_lettered_messages_to       = queue.forward_dead_lettered_messages_to
      forward_to                              = queue.forward_to
      lock_duration                           = queue.lock_duration
      max_delivery_count                      = queue.max_delivery_count
      max_message_size_in_kilobytes           = queue.max_message_size_in_kilobytes
      max_size_in_megabytes                   = queue.max_size_in_megabytes
      partitioning_enabled                    = queue.partitioning_enabled
      requires_duplicate_detection            = queue.requires_duplicate_detection
      requires_session                        = queue.requires_session
      status                                  = queue.status
    }
  }
}

output "queue_authorization_rules" {
  description = "Map of Service Bus Queue authorization rules and their generated credentials."
  sensitive   = true
  value = {
    for name, rule in azurerm_servicebus_queue_authorization_rule.queue_auth_rule : name => {
      id                                = rule.id
      name                              = rule.name
      queue_id                          = rule.queue_id
      listen                            = rule.listen
      send                              = rule.send
      manage                            = rule.manage
      primary_key                       = rule.primary_key
      primary_connection_string         = rule.primary_connection_string
      secondary_key                     = rule.secondary_key
      secondary_connection_string       = rule.secondary_connection_string
      primary_connection_string_alias   = rule.primary_connection_string_alias
      secondary_connection_string_alias = rule.secondary_connection_string_alias
    }
  }
}
