resource "azurerm_user_assigned_identity" "this" {
  count = var.create_identity ? 1 : 0

  location            = var.location
  name                = "${var.name}-user-assigned-id"
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_role_assignment" "user_aid" {
  count = var.create_identity ? 1 : 0

  principal_id = azurerm_user_assigned_identity.this.0.principal_id
  scope        = data.azurerm_subscription.primary.id

  role_definition_name = "Contributor"
}

resource "azurerm_federated_identity_credential" "this" {
  count = var.create_identity ? 1 : 0

  name                = "${var.name}-github-federated-environment-${var.env}"
  resource_group_name = data.azurerm_resource_group.this.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.this.0.id
  subject             = "repo:${var.github.org}/${var.github.repository}:environment:${var.env}"
}
