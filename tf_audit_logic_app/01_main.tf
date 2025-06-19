

resource "azurerm_logic_app_workflow" "workflow" {
  name                = "${var.prefix}-terraform-audit"
  location            = var.location
  resource_group_name = var.resource_group_name
  identity {
    type = "SystemAssigned"
  }

  workflow_parameters = {
        "$connections": jsonencode({
            "type": "Object",
            "defaultValue": {
                "azuretables": {
                    #fixme
                    "id": azurerm_api_connection.storage_account_api_connection.managed_api_id,
                    "connectionId": azurerm_api_connection.storage_account_api_connection.id,
                    "connectionName": azurerm_api_connection.storage_account_api_connection.name
                }
            }
        })
  }

  tags = var.tags
}

data "azurerm_managed_api" "storage_table" {
  name     = "azuretables"
  location = var.location
}

resource "azurerm_api_connection" "storage_account_api_connection" {
  name                = "${var.prefix}-tf-audit-sa-api-connection"
  resource_group_name = var.resource_group_name
  #fixme
  managed_api_id      = data.azurerm_managed_api.storage_table.id
  display_name        = "audit-sa-api-conn"

  parameter_values = {
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
  name         = "ForEachEntity"
  logic_app_id = azurerm_logic_app_workflow.workflow.id

  body = <<BODY
  {
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
                            "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('AccountNameFromSettings'))}/tables/@{encodeURIComponent('prodapply')}/entities/etag(PartitionKey='@{encodeURIComponent(items('ForEachEntity')['partitionKey'])}',RowKey='@{encodeURIComponent(items('ForEachEntity')['rowKey'])}')"
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




