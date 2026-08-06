output "amba_source_commit" {
  description = "Commit SHA del repo AMBA da cui e' stato generato data/amba_alerts.json (tracciabilita' versione soglie)."
  value       = local.amba_dataset.source_commit
}

output "target_namespaces" {
  description = "Namespace effettivamente considerati dopo il filtro included_namespaces/excluded_namespaces."
  value       = local.namespaces_with_defs
}

output "discovered_resource_counts" {
  description = "Numero di risorse scoperte per namespace, utile per validare la discovery prima di controllare il numero di alert generate."
  value = {
    for ns in local.namespaces_with_defs :
    ns => length(data.azurerm_resources.discovered[ns].resources)
  }
}

output "alert_count_by_namespace" {
  description = "Numero di alert create per namespace (risorse scoperte x definizioni AMBA applicabili)."
  value = {
    for ns in local.namespaces_with_defs :
    ns => length([
      for k, v in local.resource_alert_pairs : k if v.namespace == ns
    ])
  }
}

output "total_alert_count" {
  description = "Numero totale di azurerm_monitor_metric_alert create dal modulo."
  value       = length(azurerm_monitor_metric_alert.this)
}
