variable "https_endpoint" {
  type        = string
  description = "Https endpoint to check"
}

variable "location_string" {
  type        = string
  description = "(Required) Location string"
}

variable "time_trigger" {
  type        = string
  description = "cron trigger pattern"
  default     = "*/1 * * * *"
}

variable "expiration_delta_in_days" {
  type        = string
  default     = "7"
  description = "(Optional)"
}

#
# 🔒 KV
#
variable "keyvault_name" {
  type        = string
  description = "(Required) Keyvault name"
}

variable "keyvault_tenant_id" {
  type        = string
  description = "(Required) Keyvault tenant id"
}

variable "kv_secret_name_for_application_insights_connection_string" {
  type        = string
  description = "(Required) The name of the secret inside the kv that contains the application insights connection string"
}

#
# 🪖 HELM & Kubernetes
#
variable "namespace" {
  type        = string
  description = "(Required) Namespace where the helm chart will be installed"
}

variable "helm_chart_present" {
  type        = bool
  description = "Is this helm chart present?"
  default     = true
}

variable "helm_chart_version" {
  type        = string
  description = "Helm chart version for the tls checker application"
  default     = "7.6.0"
}

variable "helm_chart_image_name" {
  type        = string
  description = "Docker image name"
  default     = "ghcr.io/pagopa/infra-ssl-check"
}

variable "helm_chart_image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "v1.3.4@sha256:c3d45736706c981493b6216451fc65e99a69d5d64409ccb1c4ca93fef57c921d"
}

#
# App Insigths and alert
#
variable "application_insights_resource_group" {
  type        = string
  description = "(Required) Application Insights resource group"
}

variable "application_insights_id" {
  type        = string
  description = "(Required) Application Insights id"
}

variable "application_insights_action_group_ids" {
  type        = list(string)
  description = "(Required) Application insights action group ids"
}

variable "alert_name" {
  type        = string
  description = "(Optional) Alert name"
  default     = null
}

variable "alert_enabled" {
  type        = bool
  description = "(Optional) Is this alert enabled?"
  default     = true
}

#
# Workload Identity
#

variable "workload_identity_service_account_name" {
  type        = string
  description = "Service account name linked to workload identity"
  default     = null
}

variable "workload_identity_client_id" {
  type        = string
  description = "ClientID in form of 'qwerty123-a1aa-1234-xyza-qwerty123' linked to workload identity"
  default     = null
}

variable "pod_ram" {
  type        = number
  description = "Pod request and limit for RAM memory (in `Mi`)"
  default     = 30
}

variable "pod_cpu" {
  type        = number
  description = "Pod request and limit for CPU (in `m`)"
  default     = 10
}

variable "tolerations" {
  type        = string
  description = "Pod tolerations"
  default     = ""
}

variable "affinity" {
  type        = string
  description = "Pod Affinity and Anti-Affinity"
  default     = ""
}

variable "cert_mounter_chart_version" {
  type        = string
  description = "(Optional) Cert mounter chart version"
  default     = "2.0.2"
}

variable "helm_release_name" {
  type        = string
  description = "(Optional) Cert Mounter release name. Changed this field force the helm destroy and re-install"
  default     = "cert-mounter-blueprint"
}

variable "certificates" {
  type = map(object({
    https_endpoint                                            = optional(string)
    certificate_name                                          = optional(string)
    location_string                                           = optional(string)
    alert_name                                                = optional(string)
    namespace                                                 = optional(string)
    time_trigger                                              = optional(string)
    expiration_delta_in_days                                  = optional(string)
    keyvault_name                                             = optional(string)
    keyvault_tenant_id                                        = optional(string)
    kv_secret_name_for_application_insights_connection_string = optional(string)
    service_account_name                                      = optional(string)
    workload_identity_client_id                               = optional(string)
    helm_chart_present                                        = optional(bool)
    helm_chart_version                                        = optional(string)
    helm_chart_image_name                                     = optional(string)
    helm_chart_image_tag                                      = optional(string)
    alert_enabled                                             = optional(bool)
    application_insights_resource_group                       = optional(string)
    application_insights_id                                   = optional(string)
    application_insights_action_group_ids                     = optional(list(string))
    pod_ram                                                   = optional(number)
    pod_cpu                                                   = optional(number)
    tolerations                                               = optional(string)
    affinity                                                  = optional(string)
    cert_mounter_chart_version                                = optional(string)
    release_name                                              = optional(string)
  }))
  description = "(Optional) Additional certificates to monitor and mount, keyed by an arbitrary name. Each key deploys both a TLS checker release with its own metric alert (for `https_endpoint`) and a certificate mounter release (for `certificate_name`), so one entry maps to one endpoint/certificate pair. Any attribute left unset falls back to the corresponding top-level variable (`https_endpoint`, `location_string`, `alert_name`, `namespace`, `time_trigger`, `expiration_delta_in_days`, `keyvault_name`, `keyvault_tenant_id`, `kv_secret_name_for_application_insights_connection_string`, `workload_identity_service_account_name`, `workload_identity_client_id`, `helm_chart_present`, `helm_chart_version`, `helm_chart_image_name`, `helm_chart_image_tag`, `alert_enabled`, `application_insights_resource_group`, `application_insights_id`, `application_insights_action_group_ids`, `pod_ram`, `pod_cpu`, `tolerations`, `affinity`, `cert_mounter_chart_version`), except `certificate_name`, which falls back to `replace(https_endpoint, \".\", \"-\")`, and `release_name` (certificate mounter only), which falls back to `\"$${helm_release_name}-<key>\"`. When left at the default `{}`, the module deploys a single TLS checker, alert and certificate mounter built entirely from the top-level variables, matching the previous single-certificate behavior."
  default     = {}
}
