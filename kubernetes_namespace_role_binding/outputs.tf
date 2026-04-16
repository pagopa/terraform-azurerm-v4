output "namespace_name" {
  value = kubernetes_namespace.this[0].metadata[0].name
}
