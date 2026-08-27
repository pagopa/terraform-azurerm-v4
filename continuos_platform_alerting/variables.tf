variable "included_namespaces" {
  description = <<-EOT
    Elenco dei resource provider namespace Azure (es.
    "Microsoft.App/containerApps") da includere. Se vuoto (default),
    vengono considerati tutti i namespace presenti nel dataset AMBA
    sincronizzato (vedi scripts/sync_amba_alerts.py).
  EOT
  type        = list(string)
  default     = []
}

variable "excluded_namespaces" {
  description = "Elenco dei namespace da escludere esplicitamente, applicato dopo included_namespaces."
  type        = list(string)
  default     = []
}

variable "enabled_only" {
  description = <<-EOT
    Se true (default), vengono create solo le alert marcate "enabled: true"
    nel dataset AMBA (equivalente alla categoria "Must Have" della
    documentazione ufficiale). Se false, vengono create anche le alert
    "Nice to Have" (enabled: false nel dataset), aumentando
    sensibilmente il numero di alert e il relativo costo.
  EOT
  type        = bool
  default     = true
}

variable "action_group_ids" {
  description = <<-EOT
    Elenco di action group applicati di default a tutte le alert quando
    non esiste un override specifico per namespace in
    action_group_overrides. Ogni ID genera un blocco "action" separato
    sull'alert: e' cosi' possibile notificare piu' canali (es. Nagios +
    Teams + email oncall) sulla stessa alert.
  EOT
  type        = list(string)
  default     = []
}


variable "action_group_overrides" {
  description = <<-EOT
    Override dell'elenco di action group per singolo namespace, chiave =
    resource provider namespace (es. "Microsoft.App/containerApps"),
    valore = lista di ID action group. Quando presente per un namespace,
    sostituisce interamente action_group_ids per quel namespace (non si
    sommano).
  EOT
  type        = map(list(string))
  default     = {}
}

variable "severity_overrides" {
  description = "Override della severity per singolo alert, chiave = \"<namespace>|<nome alert AMBA>\" (es. \"Microsoft.App/containerApps|RestartCount\"), valore = severity 0-4."
  type        = map(number)
  default     = {}
}

variable "threshold_overrides" {
  description = "Override della soglia per singolo alert (solo StaticThresholdCriterion), stessa chiave di severity_overrides."
  type        = map(number)
  default     = {}
}

variable "tags" {
  description = "Tag applicati a tutte le risorse azurerm_monitor_metric_alert create dal modulo."
  type        = map(string)
  default     = {}
}

variable "action_group_metric_add_by_metric" {
  description = <<-EOT
    Aggiunge dell'elenco di action group per singolo alert, stessa
    chiave di severity_overrides/threshold_overrides:
    "<namespace>|<nome alert AMBA>" (es.
    "Microsoft.ContainerService/managedClusters|etcd_database_usage_percentage"),
    valore = lista di ID action group. Se
    presente per un alert, aggiunge sia action_group_overrides sia
    action_group_ids per quell'alert specifico.
  EOT
  type        = map(list(string))
  default     = {}
}