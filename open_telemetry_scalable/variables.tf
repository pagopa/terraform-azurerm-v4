variable "otel_kube_namespace" {
  type        = string
  description = "Namespace where to install the OpenTelemetry resources"
  nullable    = false
}

variable "create_namespace" {
  type        = bool
  default     = false
  description = "If true creates the namespace used by otel, expects it to exist otherwise. Keep false when deploying side by side with the legacy 'open_telemetry' module on the same namespace"
}

variable "install_operator" {
  type        = bool
  default     = true
  description = "If true installs the OpenTelemetry operator Helm release. Set to false when the operator is already installed on the cluster (e.g. by the legacy 'open_telemetry' module): the operator is cluster-wide and cannot be installed twice"
}

variable "opentelemetry_operator_helm_version" {
  type        = string
  default     = null
  description = "Helm chart version for otel operator. Required when 'install_operator' is true"

  validation {
    condition     = var.opentelemetry_operator_helm_version == null || (can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.opentelemetry_operator_helm_version)) && (tonumber(split(".", var.opentelemetry_operator_helm_version)[0]) > 0 || tonumber(split(".", var.opentelemetry_operator_helm_version)[1]) >= 58))
    error_message = "The OpenTelemetry operator version must be >= 0.58.0"
  }

  validation {
    condition     = !var.install_operator || var.opentelemetry_operator_helm_version != null
    error_message = "'opentelemetry_operator_helm_version' is required when 'install_operator' is true."
  }
}

variable "operator_helm_release_name" {
  type        = string
  default     = "opentelemetry-cloud-operator-scalable"
  description = "Name of the operator Helm release, used only when 'install_operator' is true"
}

variable "collector_name" {
  type        = string
  default     = "otel-scalable"
  description = "Base name of the collectors. The load balancer tier is named '<collector_name>-lb' and the tail sampling tier '<collector_name>-sampling'. Must differ from the names used by the legacy module ('otel')"
  nullable    = false
}

variable "elasticsearch_apm_host" {
  type        = string
  description = "Host where the otel collector will send the collected apm"
  nullable    = false
}

variable "elasticsearch_api_key" {
  type        = string
  sensitive   = true
  description = "Api key used by the otel collector"
  nullable    = false
}

variable "affinity_selector" {
  type = object({
    key   = string
    value = string
  })
  default     = null
  description = "Affinity selector configuration for the opentelemetry operator pods"
}

variable "grpc_receiver_port" {
  type        = number
  description = "Port of the grpc OTLP receiver exposed to applications by the load balancer tier"
  default     = 4317
}

variable "sampling_receiver_port" {
  type        = number
  description = "Port of the grpc OTLP receiver of the tail sampling tier, receives traffic from the load balancer tier only"
  default     = 4317
}

variable "deployment_env" {
  type        = string
  description = "Deployment.environment tag value"
  nullable    = false
}

variable "elastic_namespace" {
  type        = string
  description = "Elastic namespace used to store the apm data. defaults to 'default'"
  default     = "default"
}

variable "load_balancer" {
  type = object({
    replicas          = optional(number, 2)
    resolver_interval = optional(string, "5s")
    resolver_timeout  = optional(string, "1s")
    resources = optional(object({
      requests = optional(map(string))
      limits   = optional(map(string))
    }))
    memory_limiter = optional(object({
      memory_limit_mib = optional(number, 1024)
      spike_limit_mib  = optional(number, 256)
      check_interval   = optional(string, "1s")
    }), {})
  })
  description = "Stateless tier receiving telemetry from applications. It routes the spans of each trace to the same sampling pod (loadbalancing exporter, routing_key traceID). 'resources.requests' and 'resources.limits' are maps like { cpu = \"500m\", memory = \"1Gi\" }"
  default     = {}
  nullable    = false

  validation {
    condition     = var.load_balancer.replicas >= 1
    error_message = "'load_balancer.replicas' must be >= 1."
  }
}

variable "sampling" {
  type = object({
    replicas = optional(number, 3)
    resources = optional(object({
      requests = optional(map(string))
      limits   = optional(map(string))
    }))
    memory_limiter = optional(object({
      memory_limit_mib = optional(number, 4096)
      spike_limit_mib  = optional(number, 1024)
      check_interval   = optional(string, "1s")
    }), {})
  })
  description = "Stateful tier (StatefulSet) performing the tail sampling. Each pod receives all the spans of the traces assigned to it. Changing 'replicas' reshuffles the trace assignment: traces in flight during the change may be sampled incompletely. 'resources.requests' and 'resources.limits' are maps like { cpu = \"1\", memory = \"5Gi\" }"
  default     = {}
  nullable    = false

  validation {
    condition     = var.sampling.replicas >= 1
    error_message = "'sampling.replicas' must be >= 1."
  }
}

variable "otlp_exporter_config" {
  type = object({
    queue_size     = optional(number, 1000)
    consumers      = optional(number, 10)
    batch_timeout  = optional(string, "1s")
    batch_size     = optional(number, 1024)
    batch_max_size = optional(number, 2048)
  })
  description = "Configuration for the OTLP exporters and batch processors"
  default     = {}
  nullable    = false
}

variable "tail_sampling" {
  type = object({
    enabled                    = optional(bool, true)
    probes_sampling_percentage = optional(number, 1)
    sampling_percentage        = optional(number, 50)
    probe_paths                = optional(list(string), [])
    num_traces                 = optional(number, 50000)
    decision_wait              = optional(string, "30s")
  })
  description = "Tail Sampling configuration of the sampling tier"
  default     = {}
  nullable    = false
}

variable "head_sampling" {
  type = object({
    enabled             = optional(bool, false)
    sampling_percentage = optional(number, 75)
  })
  description = "Head Sampling configuration of the load balancer tier (applied by trace id, so consistent across pods)"
  default     = {}
  nullable    = false
}
