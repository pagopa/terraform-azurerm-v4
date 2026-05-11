###############################################################################
# Outputs - HAProxy Ingress Controller Module
###############################################################################

output "namespace" {
  description = "Namespace where HAProxy Ingress Controller is installed."
  value       = kubernetes_namespace_v1.haproxy_ingress.0.metadata[0].name
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.haproxy_ingress.name
}

output "release_status" {
  description = "Helm release status."
  value       = helm_release.haproxy_ingress.status
}

output "chart_version" {
  description = "Installed Helm chart version."
  value       = helm_release.haproxy_ingress.version
}

output "ingress_class_name" {
  description = "IngressClass name registered by HAProxy."
  value       = var.ingress_class_name
}

output "load_balancer_ip" {
  description = "Assigned Load Balancer IP (if service_type=LoadBalancer and a static IP is configured)."
  value       = var.load_balancer_ip
}

output "metrics_port" {
  description = "Port on which HAProxy exposes Prometheus metrics."
  value       = var.metrics_port
}
