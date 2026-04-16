locals {
  workload_identity_name                        = var.workload_identity_name != null ? var.workload_identity_name : "${var.workload_identity_name_prefix}-workload-identity"
  workload_identity_client_id_secret_name_title = "${local.workload_identity_name}-client-id"
  workload_identity_service_account_name_title  = "${local.workload_identity_name}-service-account-name"
}
