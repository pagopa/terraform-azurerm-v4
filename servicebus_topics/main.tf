locals {
  # Map of <topic_names, topic>
  topics = { for t in var.servicebus_topics : t.name => t }

  # Map of <authorization_key, authorization(topic, properties)>
  key_topic_map = {
    for tk in flatten([
      for t in var.servicebus_topics : [
        for k in t.keys : {
          key_name   = k.name
          topic_name = t.name
          listen     = k.listen
          send       = k.send
          manage     = k.manage
        }
      ]
      ]) : "${tk.topic_name}/${tk.key_name}" => {
      key_name   = tk.key_name
      topic_name = tk.topic_name
      listen     = tk.listen
      send       = tk.send
      manage     = tk.manage
    }
  }

  topic_map = {
    for name, topic in azurerm_servicebus_topic.topics : name => topic.id
  }

  subscription_map = {
    for subscription in flatten([
      for topic in var.servicebus_topics : [
        for subscription in topic.subscriptions : {
          key                                       = "${topic.name}/${subscription.name}"
          topic_name                                = topic.name
          name                                      = subscription.name
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
          client_scoped_subscription                = subscription.client_scoped_subscription
        }
      ]
    ]) : subscription.key => subscription
  }

  subscription_rule_map = {
    for rule in flatten([
      for topic in var.servicebus_topics : [
        for subscription in topic.subscriptions : [
          for rule in subscription.rules : {
            key                = "${topic.name}/${subscription.name}/${rule.name}"
            subscription_key   = "${topic.name}/${subscription.name}"
            name               = rule.name
            filter_type        = rule.filter_type
            sql_filter         = rule.sql_filter
            action             = rule.action
            correlation_filter = rule.correlation_filter
          }
        ]
      ]
    ]) : rule.key => rule
  }
}

resource "azurerm_servicebus_topic" "topics" {
  for_each = local.topics

  name                                    = each.value.name
  namespace_id                            = var.servicebus_namespace_id
  status                                  = each.value.status
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  default_message_ttl                     = each.value.default_message_ttl
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  batched_operations_enabled              = each.value.batched_operations_enabled
  express_enabled                         = each.value.express_enabled
  partitioning_enabled                    = each.value.partitioning_enabled
  max_message_size_in_kilobytes           = each.value.max_message_size_in_kilobytes
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  support_ordering                        = each.value.support_ordering
}

resource "azurerm_servicebus_topic_authorization_rule" "topic_auth_rules" {
  for_each = local.key_topic_map

  name     = each.value.key_name
  topic_id = local.topic_map[each.value.topic_name]

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage

  depends_on = [
    azurerm_servicebus_topic.topics
  ]
}

resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = local.subscription_map

  name                                      = each.value.name
  topic_id                                  = local.topic_map[each.value.topic_name]
  max_delivery_count                        = each.value.max_delivery_count
  auto_delete_on_idle                       = each.value.auto_delete_on_idle
  default_message_ttl                       = each.value.default_message_ttl
  lock_duration                             = each.value.lock_duration
  dead_lettering_on_message_expiration      = each.value.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.dead_lettering_on_filter_evaluation_error
  batched_operations_enabled                = each.value.batched_operations_enabled
  requires_session                          = each.value.requires_session
  forward_to                                = each.value.forward_to
  forward_dead_lettered_messages_to         = each.value.forward_dead_lettered_messages_to
  status                                    = each.value.status
  client_scoped_subscription_enabled        = each.value.client_scoped_subscription_enabled

  dynamic "client_scoped_subscription" {
    for_each = each.value.client_scoped_subscription == null ? [] : [each.value.client_scoped_subscription]
    content {
      client_id                               = client_scoped_subscription.value.client_id
      is_client_scoped_subscription_shareable = client_scoped_subscription.value.is_client_scoped_subscription_shareable
      is_client_scoped_subscription_durable   = client_scoped_subscription.value.is_client_scoped_subscription_durable
    }
  }

  depends_on = [
    azurerm_servicebus_topic.topics
  ]
}

resource "azurerm_servicebus_subscription_rule" "subscription_rules" {
  for_each = local.subscription_rule_map

  name            = each.value.name
  subscription_id = azurerm_servicebus_subscription.subscriptions[each.value.subscription_key].id
  filter_type     = each.value.filter_type
  sql_filter      = each.value.sql_filter
  action          = each.value.action

  dynamic "correlation_filter" {
    for_each = each.value.correlation_filter == null ? [] : [each.value.correlation_filter]
    content {
      content_type        = correlation_filter.value.content_type
      correlation_id      = correlation_filter.value.correlation_id
      label               = correlation_filter.value.label
      message_id          = correlation_filter.value.message_id
      reply_to            = correlation_filter.value.reply_to
      reply_to_session_id = correlation_filter.value.reply_to_session_id
      session_id          = correlation_filter.value.session_id
      to                  = correlation_filter.value.to
      properties          = correlation_filter.value.properties
    }
  }

  depends_on = [
    azurerm_servicebus_subscription.subscriptions
  ]
}
