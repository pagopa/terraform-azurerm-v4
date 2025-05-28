data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_logic_app_workflow" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  workflow_parameters = var.workflow.workflow_parameters
  workflow_schema     = var.workflow.workflow_schema
  workflow_version    = var.workflow.workflow_version

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_logic_app_trigger_http_request" "this" {
  name         = "TriggerHTTPS"
  method       = "GET"
  logic_app_id = azurerm_logic_app_workflow.this.id
  schema       = <<SCHEMA
{}
SCHEMA
}

resource "azurerm_logic_app_action_http" "this" {
  name         = "Trigger Workflow on Github"
  logic_app_id = azurerm_logic_app_workflow.this.id
  method       = "POST"
  headers = {
    "Accept"        = "application/vnd.github.everest-preview+json"
    "Authorization" = "token ${var.github.pat}"
  }
  body = <<SCHEMA
{
  "event_type": "${var.event_type}"
}
SCHEMA
  uri  = "https://api.github.com/repos/${var.github.org}/${var.github.repository}/dispatches"
}

resource "azurerm_logic_app_action_custom" "this" {
  for_each     = local.custom_action_schema
  body         = each.value.body
  logic_app_id = azurerm_logic_app_workflow.this.id
  name         = each.value.name
}
