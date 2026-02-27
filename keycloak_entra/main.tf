locals {
  display_name = join("-", compact([var.prefix, var.env, var.domain, "keycloak"]))
}

data "azuread_user" "ad_owners" {
  for_each            = toset(var.ad_user_owners)
  user_principal_name = each.value
}

data "azuread_group" "groups" {
  for_each     = toset(var.authorized_group_names)
  display_name = each.value
}

data "azuread_service_principal" "graph" {
  display_name = "Microsoft Graph"
}

resource "azuread_application" "keycloak" {
  display_name = local.display_name
  owners = [
    for i in data.azuread_user.ad_owners : i.object_id
  ]

  web {
    redirect_uris = var.redirect_uris
    logout_url    = var.logout_url
  }

  # Only include groups explicitly assigned to the Enterprise Application to avoid token size issues.
  group_membership_claims = ["ApplicationGroup"]

  required_resource_access {
    # Well-known ID for Microsoft Graph API
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      # ID for delegated permission "User.Read" (Sign in and read user profile)
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }

  optional_claims {
    # Essential for role mapping in Keycloak.
    id_token {
      name      = "groups"
      essential = true
    }
    # Used to populate First Name, Last Name, and Email in the Keycloak user profile.
    id_token {
      name      = "given_name"
      essential = false
    }
    id_token {
      name      = "family_name"
      essential = false
    }
    id_token {
      name      = "email"
      essential = false
    }
  }
}

# Instantiate the Enterprise Application (Service Principal) for the App Registration.
# This object is required to manage local directory assignments, such as users and groups.
resource "azuread_service_principal" "keycloak_sp" {
  client_id = azuread_application.keycloak.client_id
  owners = [
    for i in data.azuread_user.ad_owners : i.object_id
  ]
}

# Automatically grant Admin Consent for the required Microsoft Graph permissions.
# This prevents users from being prompted to manually approve access during their first login.
resource "azuread_service_principal_delegated_permission_grant" "consent" {
  service_principal_object_id          = azuread_service_principal.keycloak_sp.object_id
  resource_service_principal_object_id = data.azuread_service_principal.graph.object_id
  claim_values                         = ["User.Read"]
}

# Assign specific AD groups to the Enterprise Application.
# Using the "00000000-0000-0000-0000-000000000000" ID assigns the "Default Access" role,
# which is required for the group's claims to be included in the OIDC token.
resource "azuread_app_role_assignment" "keycloak_groups" {
  for_each = data.azuread_group.groups

  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = each.value.object_id
  resource_object_id  = azuread_service_principal.keycloak_sp.object_id
}

# Generate a client secret for the application to enable OIDC confidential flow.
# This secret is used by Keycloak to exchange the authorization code for tokens.
resource "azuread_application_password" "client_secret" {
  application_id = azuread_application.keycloak.id
  display_name   = "Keycloak Identity Provider Secret"
}