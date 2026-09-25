locals {
  # Map of <topic_names, topic>
  topics = { for t in var.servicebus_topics : t.name => t }

  # List of topic names
  topic_names = [for t in var.servicebus_topics : t.name]

  # List of topic values
  topic_values = [for t in var.servicebus_topics : t]

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
    for idx, name in local.topic_names : name =>
    azurerm_servicebus_topic.topic[idx].id
  }
}

resource "azurerm_servicebus_topic" "topic" {
  for_each = local.topic_values

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

resource "azurerm_servicebus_topic_authorization_rule" "topic_auth_rule" {
  for_each = local.key_topic_map

  name     = each.value.key_name
  topic_id = local.topic_map[each.value.topic_name]

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage

  depends_on = [
    azurerm_servicebus_topic.topic
  ]
}
