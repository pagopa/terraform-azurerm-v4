locals {
  tier_config = {
    dev = {
      autoScaleMinReplicas = 1
      autoScaleMaxReplicas = 3
      pdbMinAvailable      = 0
    }
    uat = {
      autoScaleMinReplicas = 1
      autoScaleMaxReplicas = 3
      pdbMinAvailable      = 0
    }
    prod = {
      autoScaleMinReplicas = 3
      autoScaleMaxReplicas = 6
      pdbMinAvailable      = 1
    }
  }

  selected_tier_config = local.tier_config[var.tier]

  tls_secret_name = coalesce(var.ingress_tls_secret_name, replace(var.argocd_internal_url, ".", "-"))
  effective_admin_password = (
    var.admin_password != null && var.admin_password != ""
  ) ? var.admin_password : random_password.argocd_admin_password[0].result
}

resource "helm_release" "argocd" {
  count     = var.enable_helm_release ? 1 : 0
  name      = "argo"
  chart     = "https://github.com/argoproj/argo-helm/releases/download/argo-cd-${var.argocd_helm_release_version}/argo-cd-${var.argocd_helm_release_version}.tgz"
  namespace = var.namespace
  wait      = true

  values = [
    templatefile("${path.module}/template/argocd_helm_setup_values.yaml", {
      ARGOCD_APPLICATION_NAMESPACES    = var.argocd_application_namespaces
      TENANT_ID                        = var.tenant_id
      APP_CLIENT_ID                    = var.entra_app_client_id
      ENTRA_ADMIN_GROUP_OBJECT_IDS     = var.entra_admin_group_object_ids
      ENTRA_DEVELOPER_GROUP_OBJECT_IDS = var.entra_developer_group_object_ids
      ENTRA_READER_GROUP_OBJECT_IDS    = var.entra_reader_group_object_ids
      ENTRA_GUEST_GROUP_OBJECT_IDS     = var.entra_guest_group_object_ids
      ARGOCD_INTERNAL_URL              = var.argocd_internal_url
      ARGOCD_INGRESS_TLS_SECRET_NAME   = local.tls_secret_name
      FORCE_REINSTALL                  = var.argocd_force_reinstall_version
      AUTO_SCALE_MIN_REPLICAS          = local.selected_tier_config.autoScaleMinReplicas
      AUTO_SCALE_MAX_REPLICAS          = local.selected_tier_config.autoScaleMaxReplicas
      PDB_MIN_AVAILABLE                = local.selected_tier_config.pdbMinAvailable
      ENABLE_ADMIN_LOGIN               = var.enable_admin_login
    })
  ]
}

#-------------------------------------------------------------------------------
# Setup post configurations
#-------------------------------------------------------------------------------
resource "random_password" "argocd_admin_password" {
  count            = var.admin_password == null || var.admin_password == "" ? 1 : 0
  length           = 12
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#$%*+-=?"
}

resource "azurerm_key_vault_secret" "argocd_admin_username" {
  count        = var.enable_store_admin_username ? 1 : 0
  key_vault_id = var.kv_id
  name         = "argocd-admin-username"
  value        = "admin"

  tags = var.tags
}

resource "azurerm_key_vault_secret" "argocd_admin_password" {
  count        = var.enable_store_admin_password ? 1 : 0
  key_vault_id = var.kv_id
  name         = "argocd-admin-password"
  value        = local.effective_admin_password

  tags = var.tags
}

resource "null_resource" "argocd_change_admin_password" {
  count = var.enable_change_admin_password ? 1 : 0

  triggers = {
    argocd_password = local.effective_admin_password
    force_reinstall = var.argocd_force_reinstall_version
  }

  provisioner "local-exec" {
    command = "kubectl -n ${var.namespace} patch secret argocd-secret -p '{\"stringData\": {\"admin.password\":  \"${bcrypt(local.effective_admin_password)}\", \"admin.passwordMtime\": \"'$(date +%FT%T%Z)'\"}}'"
  }

  depends_on = [
    # Ensure helm release is applied before patching the secret when enabled
    helm_release.argocd,
    azurerm_key_vault_secret.argocd_admin_password,
  ]
}

resource "null_resource" "restart_argocd_server" {
  count = var.enable_restart_argocd_server ? 1 : 0

  triggers = {
    force_reinstall = var.argocd_force_reinstall_version
    helm_version    = try(helm_release.argocd[0].version, "")
    helm_values     = try(helm_release.argocd[0].values[0], "")
  }

  provisioner "local-exec" {
    command = "kubectl -n ${var.namespace} rollout restart deployment/argo-argocd-server"
  }

  depends_on = [
    helm_release.argocd,
    null_resource.argocd_change_admin_password,
  ]
}

#-------------------------------------------------------------------------------
# 🛠️ Workload Identity
#-------------------------------------------------------------------------------
module "argocd_workload_identity_init" {
  count  = var.enable_workload_identity_init ? 1 : 0
  source = "../kubernetes_workload_identity_init"

  workload_identity_name_prefix         = "argocd"
  workload_identity_resource_group_name = var.workload_identity_resource_group_name
  workload_identity_location            = var.location

  tags = var.tags
}

module "argocd_workload_identity_configuration" {
  count  = var.enable_workload_identity_configuration ? 1 : 0
  source = "../kubernetes_workload_identity_configuration"

  workload_identity_name_prefix         = "argocd"
  workload_identity_resource_group_name = var.workload_identity_resource_group_name
  aks_name                              = var.aks_name
  aks_resource_group_name               = var.aks_resource_group_name
  namespace                             = var.namespace

  key_vault_id                      = var.kv_id
  key_vault_certificate_permissions = ["Get"]
  key_vault_key_permissions         = ["Get"]
  key_vault_secret_permissions      = ["Get"]

  depends_on = [module.argocd_workload_identity_init]
}

#-------------------------------------------------------------------------------
# 🌐 Network
#-------------------------------------------------------------------------------
resource "azurerm_private_dns_a_record" "argocd_ingress" {
  count               = var.enable_private_dns_a_record ? 1 : 0
  name                = var.dns_record_name_for_ingress
  zone_name           = var.internal_dns_zone_name
  resource_group_name = var.internal_dns_zone_resource_group_name
  ttl                 = 3600
  records             = [var.ingress_load_balancer_ip]
}
