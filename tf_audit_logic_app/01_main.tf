

resource "azurerm_logic_app_workflow" "workflow" {
  name                = "${var.prefix}-terraform-audit"
  location            = var.location
  resource_group_name = var.resource_group_name
  identity {
    type = "SystemAssigned"
  }

  workflow_parameters = {
        "$connections": {
            "type": "Object",
            "value": {
                "azuretables": {
                    #fixme
                    "id": "/subscriptions/ac17914c-79bf-48fa-831e-1359ef74c1d5/providers/Microsoft.Web/locations/italynorth/managedApis/azuretables",
                    "connectionId": "/subscriptions/ac17914c-79bf-48fa-831e-1359ef74c1d5/resourceGroups/d-marco-test/providers/Microsoft.Web/connections/azuretables",
                    "connectionName": "azuretables"
                }
            }
        }
  }

  tags = var.tags
}


resource "azurerm_api_connection" "storage_account_api_connection" {
  name                = "${var.prefix}-tf-audit-sa-api-connection"
  resource_group_name = var.resource_group_name
  #fixme
  managed_api_id      = "/subscriptions/ac17914c-79bf-48fa-831e-1359ef74c1d5/providers/Microsoft.Web/locations/italynorth/managedApis/azuretables"
  display_name        = "audit-sa-api-conn"

  parameter_values = {
    keyBasedAuth = {
      #fixme
      storageaccount = var.storage_account_settings.name
    }
  }

  tags = var.tags

  # lifecycle {
  #   # NOTE: since the connectionString is a secure value it's not returned from the API
  #   ignore_changes = ["parameter_values"]
  # }
}


resource "azurerm_logic_app_trigger_recurrence" "trigger" {
  name         = "RecurrenceTrigger"
  logic_app_id = azurerm_logic_app_workflow.workflow.id
  frequency    = var.trigger.frequency
  interval     = var.trigger.interval
}


resource "azurerm_logic_app_action_custom" "get_entities" {
  name         = "GetEntitiesAction"
  logic_app_id = azurerm_logic_app_workflow.workflow.id

  body = <<BODY
  {
    "type": "ApiConnection",
    "inputs": {
        "host": {
            "connection": {
                "name": "@parameters('$connections')['azuretables']['connectionId']"
            }
        },
        "method": "get",
        "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('AccountNameFromSettings'))}/tables/@{encodeURIComponent('${var.storage_account_settings.table_name}')}/entities",
        "queries": {
            "$filter": "Watched eq false"
        }
    },
    "runAfter": {}
  }
  BODY
}
resource "azurerm_logic_app_action_custom" "elaborate_entity" {
  name         = "ElaborateEntityAction"
  logic_app_id = azurerm_logic_app_workflow.workflow.id

  body = <<BODY
  {
      "ForEachEntity: {
      "foreach": "@body('${azurerm_logic_app_action_custom.get_entities.name}')?['value']",
      "actions": {
          "CheckSkipPolicy": {
              "actions": {
                  "NotifySlackSkipPolicy": {
                      "type": "Http",
                      "inputs": {
                          "uri": "${var.slack_webhook_url}",
                          "method": "POST",
                          "headers": {
                              "Content-Type": "application/json"
                          },
                          "body": {
                              "text": "Eseguito apply in prod con skip policy",
                              "blocks": [
                                  {
                                      "type": "section",
                                      "fields": [
                                          {
                                              "type": "mrkdwn",
                                              "text": ":warning: qualcosa"
                                          }
                                      ]
                                  }
                              ]
                          }
                      },
                      "runtimeConfiguration": {
                          "contentTransfer": {
                              "transferMode": "Chunked"
                          }
                      }
                  },
                  "UpdateEntitySkipPolicy": {
                      "runAfter": {
                          "NotifySlackSkipPolicy": [
                              "Succeeded"
                          ]
                      },
                      "type": "ApiConnection",
                      "inputs": {
                          "host": {
                              "connection": {
                                  "name": "@parameters('$connections')['azuretables']['connectionId']"
                              }
                          },
                          "method": "patch",
                          "body": {
                              "Watched": true
                          },
                          "headers": {
                              "If-Match": "*"
                          },
                          "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('AccountNameFromSettings'))}/tables/@{encodeURIComponent('prodapply')}/entities/etag(PartitionKey='@{encodeURIComponent(items('For_each')['partitionKey'])}',RowKey='@{encodeURIComponent(items('For_each')['rowKey'])}')"
                      }
                  }
              },
              "else": {
                  "actions": {
                      "UpdateEntity": {
                          "runAfter": {
                              "NotifySlack": [
                                  "Succeeded"
                              ]
                          },
                          "type": "ApiConnection",
                          "inputs": {
                              "host": {
                                  "connection": {
                                      "name": "@parameters('$connections')['azuretables']['connectionId']"
                                  }
                              },
                              "method": "patch",
                              "body": {
                                  "Watched": true
                              },
                              "headers": {
                                  "If-Match": "*"
                              },
                              "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('AccountNameFromSettings'))}/tables/@{encodeURIComponent('prodapply')}/entities/etag(PartitionKey='@{encodeURIComponent(items('For_each')['partitionKey'])}',RowKey='@{encodeURIComponent(items('For_each')['rowKey'])}')"
                          }
                      },
                      "NotifySlack": {
                          "type": "Http",
                          "inputs": {
                              "uri": "${var.slack_webhook_url}",
                              "method": "POST",
                              "headers": {
                                  "Content-Type": "application/json"
                              },
                              "body": {
                                  "text": "Eseguito apply in prod. policy valide",
                                  "blocks": [
                                      {
                                          "type": "section",
                                          "fields": [
                                              {
                                                  "type": "mrkdwn",
                                                  "text": ":warning: qualcosa"
                                              }
                                          ]
                                      }
                                  ]
                              }
                          },
                          "runtimeConfiguration": {
                              "contentTransfer": {
                                  "transferMode": "Chunked"
                              }
                          }
                      }
                  }
              },
              "expression": {
                  "and": [
                      {
                          "equals": [
                              "@items('ForEachEntity')['SkipPolicy']",
                              true
                          ]
                      }
                  ]
              },
              "type": "If"
          }
      },
      "runAfter": {
          "${azurerm_logic_app_action_custom.get_entities.name}": [
              "Succeeded"
          ]
      },
      "type": "Foreach"
  }
  BODY
}




