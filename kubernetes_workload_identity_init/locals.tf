locals {
  workload_identity_name = var.workload_identity_name != null ? var.workload_identity_name : "${var.workload_identity_name_prefix}-workload-identity"
}
