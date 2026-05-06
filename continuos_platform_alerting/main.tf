# ============================================================
# DATA SOURCE: Discovery risorse  per dominio
# ============================================================
# Per ogni dominio in var.alerting_domains, recupera dinamicamente
# tutte le risorse Azure  taggate con quel dominio.
data "azurerm_resources" "this" {
  for_each = toset(var.alerting_domains)
  type     = var.azure_resource_type

  required_tags = {
    domain = each.key
  }
}

locals {
  # ============================================================
  # custom_action_group_map
  # ============================================================
  # Converte la lista di input in una map indicizzata per chiave,
  # per permettere lookup O(1) nella risoluzione degli action group.
  custom_action_group_map = {
    for item in var.global_custom_action_group :
    item.key => item.action_groups
  }

  # ============================================================
  # resource_id_map
  # ============================================================
  # Appiattisce la struttura per dominio restituita dal data source
  # producendo una lista piatta di oggetti  con i campi
  # essenziali per la creazione degli alert.
  resource_id_map = flatten([
    for rp in data.azurerm_resources.this : [
      for r in rp.resources : {
        resource_name = r.name
        resource_rg   = r.resource_group_name
        resource_id   = r.id
      }
    ]
  ])

  # ============================================================
  # resource_metric_map
  # ============================================================
  # Cross join risorsa × metriche: ogni elemento rappresenta un
  # singolo alert da creare (una metrica su una istanza Redis).
  #
  # Logica di risoluzione action group (dal più specifico al più generico):
  #   1. "{resource_name}-{metric_name}" → override per risorsa + metrica
  #   2. "{resource_name}"               → override per risorsa
  #   3. "default"                        → fallback globale
  resource_metric_map = flatten([
    for rp in local.resource_id_map : [
      for m in var.redis_metric_alerts : {
        resource_name       = rp.resource_name
        resource_rg         = rp.resource_rg
        resource_id         = rp.resource_id
        metric_name      = m.metric_name
        metric_namespace = m.metric_namespace
        aggregation      = m.aggregation
        operator         = m.operator
        threshold        = m.threshold
        frequency        = m.frequency
        window_size      = m.window_size
        severity         = m.severity
        action_group = try(
          local.custom_action_group_map["${rp.resource_name}-${m.metric_name}"],
          try(
            local.custom_action_group_map[rp.resource_name],
            local.custom_action_group_map["default"]
          )
        )
      }
    ]
  ])

  # ============================================================
  # resource_action_group_map
  # ============================================================
  # Appiattisce il campo action_group (lista) di ogni alert,
  # producendo una coppia (alert, action group) per ogni elemento.
  # Necessario per il lookup individuale degli action group via
  # data source.
  resource_action_group_map = flatten([
    for rp in local.resource_metric_map : [
      for ag in rp.action_group : {
        resource_name                       = rp.resource_name
        metric_name                      = rp.metric_name
        action_group_name                = ag.action_group_name
        action_group_name_resource_group = ag.resource_group_name
      }
    ]
  ])
}

# ============================================================
# DATA SOURCE: Lookup degli Action Group referenziati
# ============================================================
# Recupera l'ID ARM di ogni action group unico referenziato
# negli alert. La chiave composta garantisce unicità anche
# quando lo stesso action group appare su più alert.
data "azurerm_monitor_action_group" "this" {
  for_each = {
    for val in local.resource_action_group_map :
    "${val.resource_name}-${val.metric_name}-${val.action_group_name}" => val
  }

  resource_group_name = each.value.action_group_name_resource_group
  name                = each.value.action_group_name
}

# ============================================================
# RESOURCE: Metric Alert per ogni combinazione risorsa × metrica
# ============================================================
resource "azurerm_monitor_metric_alert" "this" {
  for_each = {
    for val in local.resource_metric_map :
    "${val.resource_name}-${val.metric_name}" => val
  }

  enabled             = var.resource_alerts_enabled
  name                = "${each.value.resource_name}-${upper(each.key)}"
  resource_group_name = each.value.resource_rg
  scopes              = [each.value.resource_id]
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  severity            = each.value.severity

  # Collega tutti gli action group risolti per questo alert.
  dynamic "action" {
    for_each = data.azurerm_monitor_action_group.this
    content {
      action_group_id    = action.value["id"]
      webhook_properties = null
    }
  }

  criteria {
    aggregation      = each.value.aggregation
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  tags = var.tags
}
