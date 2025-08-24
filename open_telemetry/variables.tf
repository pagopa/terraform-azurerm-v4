variable "otel_kube_namespace" {
  type        = string
  description = "Namespace where to install the elastic agent resources"
}

variable "opentelemetry_operator_helm_version" {
  type        = string
  description = "Helm chart version for otel operator"
}

variable "elasticsearch_apm_host" {
  type        = string
  description = "Host where the otel collector will send the collected apm"
}

variable "elasticsearch_api_key" {
  type        = string
  sensitive   = true
  description = "Api key used by the elastic agent"
}

variable "affinity_selector" {
  type = object({
    key   = string
    value = string
  })
  default     = null
  description = "Affinity selector configuration for opentelemetry pods"
}

variable "grpc_receiver_port" {
  type        = number
  description = "Otel collector grpc receiver port"
  default     = 4317
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "If true creates the namespace used by otel, expects it to be created otherwise"
}

variable "deployment_env" {
  type        = string
  description = "Deployment.environment tag value"
}

variable "elastic_namespace" {
  type        = string
  description = "Elastic namespace used to store the apm data. defaults to 'default'"
  default     = "default"
}


variable "sampling" {
  type = object({
    enabled                    = bool
    probes_sampling_percentage = optional(number, 1)
    sampling_percentage        = optional(number, 50)
    probe_paths                = optional(list(string), [])
  })
  description = "Sampling configuration for the OpenTelemetry collector traces"
  default = {
    enabled                    = false
    probes_sampling_percentage = 1
    sampling_percentage        = 50
    probe_paths                = []
  }
}
