output "topic_ids" {
  description = "Map of Service Bus Topic names to their resource IDs."
  value       = { for name, topic in azurerm_servicebus_topic.topics : topic.name => topic.id }
}

output "topics" {
  description = "Map of Service Bus Topic names to their main resource attributes."
  value = {
    for name, topic in azurerm_servicebus_topic.topics : topic.name => {
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
    for name, rule in azurerm_servicebus_topic_authorization_rule.topic_auth_rules : name => {
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

output "subscription_ids" {
  description = "Map of Service Bus Topic subscription composite keys to their resource IDs."
  value       = { for name, subscription in azurerm_servicebus_subscription.subscriptions : name => subscription.id }
}

output "subscriptions" {
  description = "Map of Service Bus Topic subscription composite keys to their main resource attributes."
  value = {
    for name, subscription in azurerm_servicebus_subscription.subscriptions : name => {
      id                                        = subscription.id
      name                                      = subscription.name
      topic_id                                  = subscription.topic_id
      max_delivery_count                        = subscription.max_delivery_count
      auto_delete_on_idle                       = subscription.auto_delete_on_idle
      default_message_ttl                       = subscription.default_message_ttl
      lock_duration                             = subscription.lock_duration
      dead_lettering_on_message_expiration      = subscription.dead_lettering_on_message_expiration
      dead_lettering_on_filter_evaluation_error = subscription.dead_lettering_on_filter_evaluation_error
      batched_operations_enabled                = subscription.batched_operations_enabled
      requires_session                          = subscription.requires_session
      forward_to                                = subscription.forward_to
      forward_dead_lettered_messages_to         = subscription.forward_dead_lettered_messages_to
      status                                    = subscription.status
      client_scoped_subscription_enabled        = subscription.client_scoped_subscription_enabled
    }
  }
}

output "subscription_rule_ids" {
  description = "Map of Service Bus Topic subscription rule composite keys to their resource IDs."
  value       = { for name, rule in azurerm_servicebus_subscription_rule.subscription_rules : name => rule.id }
}

output "subscription_rules" {
  description = "Map of Service Bus Topic subscription rule composite keys to their main resource attributes."
  value = {
    for name, rule in azurerm_servicebus_subscription_rule.subscription_rules : name => {
      id              = rule.id
      name            = rule.name
      subscription_id = rule.subscription_id
      filter_type     = rule.filter_type
      sql_filter      = rule.sql_filter
      action          = rule.action
    }
  }
}
