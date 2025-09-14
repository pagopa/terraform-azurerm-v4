locals {
  app_display_name = "argocd-${var.name_identifier}"
}

# Microsoft Graph SP (for required_resource_access + delegated grant)
data "azuread_service_principal" "graph" {
  display_name = "Microsoft Graph"
}

# Current principal (for delegated consent)
data "azurerm_client_config" "current" {}

# Resolve AKS to read OIDC issuer URL
data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group_name
}

# Resolve group object IDs from display names if provided
data "azuread_group" "argocd_groups" {
  for_each     = toset(var.entra_group_display_names)
  display_name = each.value
}

# -----------------------------------------------------------------------------
# Application Registration & Service Principal
# -----------------------------------------------------------------------------
resource "azuread_application" "argocd" {
  display_name = local.app_display_name
  owners       = var.entra_app_owners_object_ids

  web {
    redirect_uris = ["https://${var.argocd_hostname}/auth/callback"]
    logout_url    = "https://${var.argocd_hostname}/logout"
  }

  # Mobile and desktop applications platform
  public_client {
    redirect_uris = ["http://localhost:8085/auth/callback"]
  }

  group_membership_claims = [
    "ApplicationGroup"
  ]

  required_resource_access {
    resource_app_id = data.azuread_service_principal.graph.client_id

    # User.Read delegated permission
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  optional_claims {
    id_token {
      name      = "groups"
      essential = true
      source    = null
    }
  }
}

resource "azuread_service_principal" "sp_argocd" {
  client_id = azuread_application.argocd.client_id
  owners    = var.entra_app_owners_object_ids
}

# -----------------------------------------------------------------------------
# Permissions and Consent
# -----------------------------------------------------------------------------
resource "azuread_service_principal_delegated_permission_grant" "argocd_user_read_consent" {
  service_principal_object_id          = azuread_service_principal.sp_argocd.object_id
  resource_service_principal_object_id = data.azuread_service_principal.graph.object_id
  claim_values                         = ["User.Read"]
  user_object_id                       = data.azurerm_client_config.current.object_id
}

# Assign groups to Enterprise Application (ApplicationGroup claims)
resource "azuread_app_role_assignment" "argocd_group_assignments" {
  for_each = data.azuread_group.argocd_groups

  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = each.value.object_id
  resource_object_id  = azuread_service_principal.sp_argocd.object_id
}

# -----------------------------------------------------------------------------
# Workload Identity Federation
# -----------------------------------------------------------------------------
resource "azuread_application_federated_identity_credential" "argocd" {
  application_id = azuread_application.argocd.id
  display_name   = "${var.name_identifier}-argocd-server-federated-credential"
  description    = "Federated credential for the ArgoCD server service account"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = data.azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject        = "system:serviceaccount:${var.argocd_namespace}:${var.argocd_service_account_name}"
}

# -----------------------------------------------------------------------------
# Key Vault Secrets
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "argocd_entra_app_client_id" {
  key_vault_id = var.key_vault_id
  name         = var.kv_secret_app_client_id_name
  value        = azuread_application.argocd.client_id
}

resource "azurerm_key_vault_secret" "argocd_entra_app_service_account_name" {
  key_vault_id = var.key_vault_id
  name         = var.kv_secret_service_account_name
  value        = var.argocd_service_account_name
}
