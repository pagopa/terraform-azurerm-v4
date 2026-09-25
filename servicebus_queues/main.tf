locals {
  # Map of <queue_names, queue>
  queues = { for q in var.servicebus_queues : q.name => q }

  # List of queue names
  queue_names = [for q in var.servicebus_queues : q.name]

  # List of queue values
  queue_values = [for q in var.servicebus_queues : q]

  # Map of <authorization_key, authorization(queue, properties)>
  key_queue_map = {
    for qk in flatten([
      for q in var.servicebus_queues :
      [
        for k in q.keys : {
          key_name   = k.name
          queue_name = q.name
          listen     = k.listen
          send       = k.send
          manage     = k.manage
        }
      ]
      ]) : "${qk.key_name}" => {
      queue_name = qk.queue_name
      listen     = qk.listen
      send       = qk.send
      manage     = qk.manage
    }
  }

  queue_map = {
    for idx, name in local.queue_names : name =>
    azurerm_servicebus_queue.queue[idx].id
  }
}


resource "azurerm_servicebus_queue" "queues" {
  for_each = local.queue_values
  
  name                                    = each.value.name
  namespace_id                            = var.servicebus_namespace_id
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  batched_operations_enabled              = each.value.batched_operations_enabled
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  default_message_ttl                     = each.value.default_message_ttl
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  express_enabled                         = each.value.express_enabled
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  forward_to                              = each.value.forward_to
  lock_duration                           = each.value.lock_duration
  max_delivery_count                      = each.value.max_delivery_count
  max_message_size_in_kilobytes           = each.value.max_message_size_in_kilobytes
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  partitioning_enabled                    = each.value.partitioning_enabled
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  requires_session                        = each.value.requires_session
  status                                  = each.value.status
}

resource "azurerm_servicebus_queue_authorization_rule" "queue_auth_rules" {
  for_each = local.key_queue_map

  name     = each.key
  queue_id = local.queue_map[each.value.queue_name]

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage

  depends_on = [
    azurerm_servicebus_queue.queues
  ]
}
