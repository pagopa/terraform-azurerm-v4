output "topic_ids" {
  description = "Map of Service Bus Topic names to their resource IDs."
  value       = { for name, topic in azurerm_servicebus_topic.topic : topic.name => topic.id }
}

output "topics" {
  description = "Map of Service Bus Topic names to their main resource attributes."
  value = {
    for name, topic in azurerm_servicebus_topic.topic : topic.name => {
      id                                      = topic.id
      name                                    = topic.name
      namespace_id                            = topic.namespace_id
      status                                  = topic.status
      auto_delete_on_idle                     = topic.auto_delete_on_idle
      default_message_ttl                     = topic.default_message_ttl
      duplicate_detection_history_time_window = topic.duplicate_detection_history_time_window
      batched_operations_enabled              = topic.batched_operations_enabled
      express_enabled                         = topic.express_enabled
      partitioning_enabled                    = topic.partitioning_enabled
      max_message_size_in_kilobytes           = topic.max_message_size_in_kilobytes
      max_size_in_megabytes                   = topic.max_size_in_megabytes
      requires_duplicate_detection            = topic.requires_duplicate_detection
      support_ordering                        = topic.support_ordering
    }
  }
}

output "topic_authorization_rules" {
  description = "Map of Service Bus Topic authorization rules and their generated credentials."
  sensitive   = true
  value = {
    for name, rule in azurerm_servicebus_topic_authorization_rule.topic_auth_rule : name => {
      id                                = rule.id
      name                              = rule.name
      topic_id                          = rule.topic_id
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
