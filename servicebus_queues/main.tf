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


resource "azurerm_servicebus_queue" "queue" {
  count = length(local.queue_values)

  name                                    = local.queue_values[count.index].name
  namespace_id                            = var.servicebus_namespace_id
  auto_delete_on_idle                     = local.queue_values[count.index].auto_delete_on_idle
  batched_operations_enabled              = local.queue_values[count.index].batched_operations_enabled
  dead_lettering_on_message_expiration    = local.queue_values[count.index].dead_lettering_on_message_expiration
  default_message_ttl                     = local.queue_values[count.index].default_message_ttl
  duplicate_detection_history_time_window = local.queue_values[count.index].duplicate_detection_history_time_window
  express_enabled                         = local.queue_values[count.index].express_enabled
  forward_dead_lettered_messages_to       = local.queue_values[count.index].forward_dead_lettered_messages_to
  forward_to                              = local.queue_values[count.index].forward_to
  lock_duration                           = local.queue_values[count.index].lock_duration
  max_delivery_count                      = local.queue_values[count.index].max_delivery_count
  max_message_size_in_kilobytes           = local.queue_values[count.index].max_message_size_in_kilobytes
  max_size_in_megabytes                   = local.queue_values[count.index].max_size_in_megabytes
  partitioning_enabled                    = local.queue_values[count.index].partitioning_enabled
  requires_duplicate_detection            = local.queue_values[count.index].requires_duplicate_detection
  requires_session                        = local.queue_values[count.index].requires_session
  status                                  = local.queue_values[count.index].status
}

resource "azurerm_servicebus_queue_authorization_rule" "queue_auth_rule" {
  for_each = local.key_queue_map

  name     = each.key
  queue_id = local.queue_map[each.value.queue_name]

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage

  depends_on = [
    azurerm_servicebus_queue.queue
  ]
}
