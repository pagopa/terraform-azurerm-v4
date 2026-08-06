variable "resource_group_name" {
  description = <<-EOT
    Se valorizzata, limita la discovery delle risorse a questo resource
    group (le alert vengono comunque create nel resource group di
    appartenenza di ciascuna risorsa scoperta). Se null (default), la
    discovery avviene sull'intera subscription del provider azurerm
    corrente.
  EOT
  type    = string
  default = null
}

variable "required_tags" {
  description = "Filtro opzionale: limita la discovery alle risorse che espongono questi tag (chiave => valore)."
  type        = map(string)
  default     = {}
}

variable "included_namespaces" {
  description = <<-EOT
    Elenco dei resource provider namespace Azure (es.
    "Microsoft.App/containerApps") da includere. Se vuoto (default),
    vengono considerati tutti i namespace presenti nel dataset AMBA
    sincronizzato (vedi scripts/sync_amba_alerts.py).
  EOT
  type    = list(string)
  default = []
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
  type    = bool
  default = true
}

variable "action_group_id" {
  description = "Action group di default usato per tutte le alert quando non esiste un override specifico per namespace in action_group_overrides."
  type        = string
  default     = null
}

variable "action_group_overrides" {
  description = "Override dell'action group per singolo namespace, chiave = resource provider namespace (es. \"Microsoft.App/containerApps\"), valore = ID action group."
  type        = map(string)
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

