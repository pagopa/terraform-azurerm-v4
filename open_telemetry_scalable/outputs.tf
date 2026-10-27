output "load_balancer_service_endpoint" {
  description = "In-cluster OTLP gRPC endpoint (host:port) applications must send telemetry to"
  value       = "${local.lb_name}-collector.${var.otel_kube_namespace}.svc.cluster.local:${var.grpc_receiver_port}"
}

output "load_balancer_collector_name" {
  description = "Name of the OpenTelemetryCollector resource of the load balancer tier"
  value       = local.lb_name
}

output "sampling_collector_name" {
  description = "Name of the OpenTelemetryCollector resource of the tail sampling tier"
  value       = local.sampling_name
}

output "sampling_headless_hostname" {
  description = "DNS name resolved by the load balancer tier to discover the sampling pods"
  value       = local.sampling_headless_hostname
}
