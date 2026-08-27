# Discovery dinamica: una chiamata a azurerm_resources per ciascun
# namespace target, invece di richiedere all'utente di elencare a mano
# le risorse esistenti. Stesso pattern usato negli altri moduli di
# monitoring del repo (dynamic resource discovery + cross-join).
data "azurerm_resources" "discovered" {
  for_each = toset(local.namespaces_with_defs)

  type = each.value
}

locals {
  # Cross-join tra risorse scoperte e definizioni di alert AMBA del
  # namespace corrispondente. Il risultato e' una mappa piatta
  # "<resource_id>::<alert_name>" => { ...alert def + contesto risorsa },
  # pronta per il for_each della risorsa azurerm_monitor_metric_alert.
  resource_alert_pairs = merge([
    for ns in local.namespaces_with_defs : {
      for pair in setproduct(
        data.azurerm_resources.discovered[ns].resources,
        local.alert_defs_by_namespace[ns]
      ) :
      "${pair[0].id}::${pair[1].name}" => merge(pair[1], {
        namespace       = ns
        resource_id     = pair[0].id
        resource_name   = pair[0].name
        alert_name_safe = replace(replace(pair[1].name, " ", "-"), "/[^A-Za-z0-9_-]/", "")
        # Il resource group dell'alert e' quello della risorsa monitorata
        # (indice 4 di un Azure resource ID: /subscriptions/{}/resourceGroups/{}/...).
        alert_resource_group = element(split("/", pair[0].id), 4)
        override_key         = "${ns}|${pair[1].name}"
      })
    }
  ]...)

  # Risoluzione action group: override specifico per namespace, altrimenti
  # il default globale. Nessun errore se entrambi sono null: in quel caso
  # l'alert viene creata senza blocco "action" (va collegata manualmente
  # o via alert processing rule esterna).
  action_group_by_namespace = {
    for ns in local.namespaces_with_defs :
    ns => try(var.action_group_overrides[ns], var.action_group_ids)
  }
}

locals {
  amba_dataset = jsondecode(file("${path.module}/data/amba_alerts.json"))

  # Tutti i namespace per cui il dataset AMBA sincronizzato contiene
  # definizioni di alert di tipo Metric.
  all_available_namespaces = sort(keys(local.amba_dataset.namespaces))

  # Applica included_namespaces (whitelist, vuota = tutti) ed
  # excluded_namespaces (blacklist, applicata dopo).
  target_namespaces = [
    for ns in local.all_available_namespaces : ns
    if(
      (length(var.included_namespaces) == 0 || contains(var.included_namespaces, ns))
      && !contains(var.excluded_namespaces, ns)
    )
  ]

  # Ricostruzione esplicita di ogni alert con uno schema di attributi
  # fisso e identico per tutti gli elementi (indipendentemente dal
  # criterionType). sync_amba_alerts.py gia' produce un JSON omogeneo,
  # ma questa normalizzazione e' fatta anche qui, lato Terraform, come
  # difesa in profondita': se in futuro il dataset dovesse tornare ad
  # avere attribute set diversi tra gli elementi di una stessa lista
  # (es. campi presenti solo su DynamicThresholdCriterion), jsondecode()
  # produce oggetti non uniformi e setproduct()/merge() più a valle
  # falliscono con un errore di type unification poco intuitivo.
  normalized_namespaces = {
    for ns in local.all_available_namespaces : ns => [
      for a in local.amba_dataset.namespaces[ns] : {
        name                      = a.name
        description               = a.description
        metricName                = a.metricName
        criterionType             = a.criterionType
        severity                  = a.severity
        windowSize                = a.windowSize
        evaluationFrequency       = a.evaluationFrequency
        timeAggregation           = a.timeAggregation
        operator                  = a.operator
        threshold                 = try(a.threshold, null)
        autoMitigate              = try(a.autoMitigate, true)
        enabled                   = try(a.enabled, false)
        dimensions                = try(a.dimensions, [])
        alertSensitivity          = try(a.alertSensitivity, null)
        numberOfEvaluationPeriods = try(a.numberOfEvaluationPeriods, null)
        minFailingPeriodsToAlert  = try(a.minFailingPeriodsToAlert, null)
      }
    ]
  }

  # Per ciascun namespace target, le definizioni di alert normalizzate
  # e filtrate per enabled_only (Must Have vs Must+Nice to Have).
  alert_defs_by_namespace = {
    for ns in local.target_namespaces : ns => [
      for a in local.normalized_namespaces[ns] : a
      if !var.enabled_only || a.enabled
    ]
  }

  # Solo i namespace che, dopo il filtro enabled_only, hanno ancora
  # almeno una definizione di alert: evita di lanciare data source di
  # discovery inutili.
  namespaces_with_defs = [
    for ns in local.target_namespaces : ns
    if length(local.alert_defs_by_namespace[ns]) > 0
  ]
}


resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.resource_alert_pairs

  name                = "amba-${each.value.resource_name}-${each.value.alert_name_safe}"
  resource_group_name = each.value.alert_resource_group
  scopes              = [each.value.resource_id]
  description         = each.value.description

  severity      = try(var.severity_overrides[each.value.override_key], each.value.severity)
  frequency     = each.value.evaluationFrequency
  window_size   = each.value.windowSize
  auto_mitigate = each.value.autoMitigate
  enabled       = each.value.enabled

  dynamic "criteria" {
    for_each = each.value.criterionType == "StaticThresholdCriterion" ? [each.value] : []
    content {
      metric_namespace = each.value.namespace
      metric_name      = each.value.metricName
      aggregation      = each.value.timeAggregation
      operator         = each.value.operator
      threshold        = try(var.threshold_overrides[each.value.override_key], each.value.threshold)

      dynamic "dimension" {
        for_each = each.value.dimensions
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.criterionType == "DynamicThresholdCriterion" ? [each.value] : []
    content {
      metric_namespace         = each.value.namespace
      metric_name              = each.value.metricName
      aggregation              = each.value.timeAggregation
      operator                 = each.value.operator
      alert_sensitivity        = each.value.alertSensitivity
      evaluation_total_count   = each.value.numberOfEvaluationPeriods
      evaluation_failure_count = each.value.minFailingPeriodsToAlert

      dynamic "dimension" {
        for_each = each.value.dimensions
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = concat(try(
      var.action_group_metric_add_by_metric[each.value.override_key], []),
      local.action_group_by_namespace[each.value.namespace]
    )
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags

  lifecycle {
    # Il dataset AMBA a monte cambia periodicamente (nuove metriche,
    # soglie riviste): evitiamo che un giro di sync_amba_alerts.py non
    # ancora rivisto in PR provochi un drift inatteso e silenzioso sulla
    # description, che Microsoft aggiorna spesso senza cambiare la logica.
    ignore_changes = [description]
  }
}
