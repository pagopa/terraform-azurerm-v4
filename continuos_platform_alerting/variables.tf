variable "alerting_domains" {
  type        = list(string)
  description = "Lista dei domini per cui eseguire il discovery delle risorse  tramite tag."
}

variable "azure_resource_type" {
  type        = string
  description = "Tipo di risorsa Azure da cercare per il discovery."
}

variable "resource_metric_alerts" {
  type = list(object({
    metric_name      = string
    metric_namespace = string
    aggregation      = string
    operator         = string
    threshold        = number
    frequency        = string
    window_size      = string
    severity         = number
  }))
  description = "Lista delle metriche per cui creare alert su ogni istanza."
}

variable "resource_alerts_enabled" {
  type        = bool
  description = "Abilita o disabilita globalmente tutti gli alert."
  default     = true
}

variable "global_custom_action_group" {
  type = list(object({
    key = string
    action_groups = list(object({
      action_group_name  = string
      resource_group_name = string
    }))
  }))
  description = <<-EOT
    Mapping tra chiavi e action group da associare agli alert.
    La chiave può essere:
      - "default"                        → fallback globale
      - "{resource_name}"                   → override per una specifica istanza 
      - "{resource_name}-{metric_name}"     → override per una specifica istanza e metrica
  EOT
}

variable "tags" {
  type        = map(string)
  description = "Tag da applicare a tutte le risorse create dal modulo."
  default     = {}
}
