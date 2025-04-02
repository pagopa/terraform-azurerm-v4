resource "helm_release" "cert_mounter" {
  name         = replace(substr(var.helm_release_name, 0, 53), ".", "-")
  repository   = "https://pagopa.github.io/aks-helm-cert-mounter-blueprint"
  chart        = "cert-mounter-blueprint"
  version      = var.cert_mounter_chart_version
  namespace    = var.namespace
  timeout      = 120
  force_update = true

  values = [
    templatefile("${path.module}/helm/cert-mounter-workload-identity.yaml.tpl", {
      NAMESPACE                   = var.namespace,
      CERTIFICATE_NAME            = var.certificate_name,
      KEY_VAULT_NAME              = var.kv_name
      TENANT_ID                   = var.tenant_id
      SERVICE_ACCOUNT_NAME        = var.workload_identity_service_account_name
      WORKLOAD_IDENTITY_CLIENT_ID = var.workload_identity_client_id
      POD_RAM                     = var.pod_ram
      POD_CPU                     = var.pod_cpu
      TOLERATIONS                 = var.tolerations
      AFFINITY                    = var.affinity
    })
  ]
}
