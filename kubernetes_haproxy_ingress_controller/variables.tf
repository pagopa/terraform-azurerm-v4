###############################################################################
# Variables - HAProxy Ingress Controller Module
###############################################################################

# ---- Identity ----

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "haproxy-ingress"
}

variable "namespace" {
  description = "Kubernetes namespace where HAProxy Ingress Controller will be installed."
  type        = string
  default     = "haproxy-ingress"
}

variable "namespace_labels" {
  description = "Additional labels to apply to the namespace."
  type        = map(string)
  default     = {}
}

variable "namespace_annotations" {
  description = "Additional annotations to apply to the namespace."
  type        = map(string)
  default     = {}
}

# ---- Versions ----

variable "chart_version" {
  description = "Version of the haproxytech/kubernetes-ingress Helm chart."
  type        = string
  default     = "1.49.0"
}

variable "controller_image_tag" {
  description = "HAProxy controller image tag (for example '2.11.0')."
  type        = string
  default     = "3.2.6"
}

# ---- Replicas & Autoscaling ----

variable "replica_count" {
  description = "Number of controller replicas (used only when autoscaling is disabled)."
  type        = number
  default     = 2

  validation {
    condition     = var.replica_count >= 1
    error_message = "Replica count must be >= 1."
  }
}

variable "autoscaling" {
  description = "Horizontal Pod Autoscaler configuration."
  type = object({
    enabled                   = bool
    min_replicas              = number
    max_replicas              = number
    target_cpu_utilization    = number
    target_memory_utilization = number
  })
  default = {
    enabled                   = true
    min_replicas              = 2
    max_replicas              = 10
    target_cpu_utilization    = 75
    target_memory_utilization = 80
  }
}

# ---- Pod Disruption Budget ----

variable "pod_disruption_budget" {
  description = "Pod Disruption Budget configuration to ensure high availability."
  type = object({
    enabled       = bool
    min_available = number
  })
  default = {
    enabled       = true
    min_available = 1
  }
}

# ---- Resources ----

variable "resources" {
  description = "Resource requests and limits for the controller container."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  default = {
    requests_cpu    = "100m"
    requests_memory = "128Mi"
    limits_cpu      = "500m"
    limits_memory   = "512Mi"
  }
}

# ---- Namespace Resource Quota ----

variable "enable_resource_quota" {
  description = "Enable Resource Quota on the namespace."
  type        = bool
  default     = true
}

variable "namespace_quota" {
  description = "Resource Quota configuration for the namespace."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
    pods            = string
  })
  default = {
    requests_cpu    = "2"
    requests_memory = "2Gi"
    limits_cpu      = "4"
    limits_memory   = "4Gi"
    pods            = "20"
  }
}

# ---- Service ----

variable "service_type" {
  description = "Kubernetes Service type (LoadBalancer, NodePort, ClusterIP)."
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.service_type)
    error_message = "Valid values are: LoadBalancer, NodePort, ClusterIP."
  }
}

variable "service_annotations" {
  description = "Annotations for the Service (for example Azure internal Load Balancer, static IP, and so on)."
  type        = map(string)
  default     = {}
  # AKS internal Load Balancer example:
  # {
  #   "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
  # }
}

variable "load_balancer_ip" {
  description = "Pre-allocated static IP to assign to the LoadBalancer (optional)."
  type        = string
  default     = null
}

# ---- IngressClass ----

variable "ingress_class_name" {
  description = "Name of the IngressClass to register."
  type        = string
  default     = "haproxy"
}

variable "set_as_default_ingress_class" {
  description = "Set HAProxy as the default IngressClass in the cluster."
  type        = bool
  default     = false
}

# ---- TLS ----

variable "default_ssl_certificate" {
  description = "Default TLS secret (namespace/secret-name format). Requires cert-manager or a pre-existing secret."
  type        = string
  default     = null

  validation {
    condition     = var.default_ssl_certificate == null || can(regex("^[a-zA-Z0-9_./-]+/[a-zA-Z0-9_./-]+$", var.default_ssl_certificate))
    error_message = "default_ssl_certificate must be in 'namespace/secret-name' format (e.g., 'haproxy-ingress/wildcard-tls') or null."
  }
}

# ---- Monitoring ----

variable "enable_stats" {
  description = "Enable the HAProxy /stats endpoint."
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Enable Prometheus metrics exposure."
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Port on which to expose Prometheus metrics."
  type        = number
  default     = 1024
}

variable "enable_service_monitor" {
  description = "Create a ServiceMonitor object for Prometheus Operator."
  type        = bool
  default     = false
}

# ---- Network Policy ----

variable "enable_network_policy" {
  description = "Enable Network Policies in the namespace."
  type        = bool
  default     = true
}

# ---- Affinity & Topology ----

variable "anti_affinity_topology_key" {
  description = "Topology key for pod anti-affinity (distribution across nodes/zones)."
  type        = string
  default     = "kubernetes.io/hostname"
}

variable "enable_topology_spread" {
  description = "Enable TopologySpreadConstraints to distribute pods across availability zones."
  type        = bool
  default     = true
}

# ---- Logging ----

variable "log_level" {
  description = "Controller log level (debug, info, warning, error)."
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warning", "error"], var.log_level)
    error_message = "Valid values are: debug, info, warning, error."
  }
}

# ---- Helm behavior ----

variable "atomic" {
  description = "If true, the release is automatically rolled back in case of failure."
  type        = bool
  default     = true
}

variable "timeout_seconds" {
  description = "Timeout in seconds for Helm operations."
  type        = number
  default     = 300
}

# ---- Extensibility ----

variable "extra_set_values" {
  description = "Map of additional Helm values (name = value) for targeted overrides."
  type        = map(string)
  default     = {}
}

variable "extra_values_files" {
  description = "List of additional YAML contents (values files) to pass to the chart."
  type        = list(string)
  default     = []
}

variable "values_override" {
  description = "Full YAML string to override chart values (use with caution)."
  type        = string
  default     = null
}
