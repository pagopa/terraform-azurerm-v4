locals {
  service_account_default_secret_name = var.custom_service_account_default_secret_name == "" ? "${var.name}-sa-token" : var.custom_service_account_default_secret_name
}
