locals {
  slack_message = jsonencode({
	"blocks": [
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": ":warning: apply in prod"
			}
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_section",
					"elements": [
						{
							"type": "text",
							"text": "Dettagli:\n"
						}
					]
				},
				{
					"type": "rich_text_list",
					"style": "bullet",
					"indent": 0,
					"elements": [
						{
							"type": "rich_text_section",
							"elements": [
								{
									"type": "text",
									"text": "applier: "
								},
								{
									"type": "text",
									"text": "nome"
								}
							]
						},
						{
							"type": "rich_text_section",
							"elements": [
								{
									"type": "text",
									"text": "cartella: "
								},
								{
									"type": "text",
									"text": "cartella"
								}
							]
						},
						{
							"type": "rich_text_section",
							"elements": [
								{
									"type": "text",
									"text": "skipPolicy: "
								},
								{
									"type": "text",
									"text": "skippolicy"
								}
							]
						}
					]
				}
			]
		},
		{
			"type": "divider"
		},
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": "<https://google.com|Check the plan>"
			}
		},
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": "<https://google.com|Check the apply result>"
			}
		}
	]
})
}

data "azurerm_managed_api" "storage_table" {
  name     = "azuretables"
  location = var.location
}

resource "azurerm_api_connection" "storage_account_api_connection" {
  name                = "${var.prefix}-tf-audit-sa-api-connection"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.storage_table.id
  display_name        = "audit-sa-api-conn"

  parameter_values = {
    storageaccount = var.storage_account_settings.name
    sharedkey  = var.storage_account_settings.access_key
  }

  tags = var.tags

  lifecycle {
    # NOTE: since the sharedkey is a secure value it's not returned from the API
    ignore_changes = [parameter_values["sharedkey"]]
  }
}

resource "azurerm_logic_app_workflow" "workflow" {
  name                = "${var.prefix}-terraform-audit"
  location            = var.location
  resource_group_name = var.resource_group_name
  identity {
    type = "SystemAssigned"
  }

  parameters = {
    "$connections": jsonencode({
      "azuretables": {
          "id": azurerm_api_connection.storage_account_api_connection.managed_api_id,
          "connectionId": azurerm_api_connection.storage_account_api_connection.id,
          "connectionName": azurerm_api_connection.storage_account_api_connection.name
      }
    })
  }

  workflow_parameters = {
        "$connections": jsonencode({
            "type": "Object"
        })
  }

  tags = var.tags
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
                            "body": "${local.slack_message}",
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
                                "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('AccountNameFromSettings'))}/tables/@{encodeURIComponent('prodapply')}/entities/etag(PartitionKey='@{encodeURIComponent(items('ForEachEntity')['partitionKey'])}',RowKey='@{encodeURIComponent(items('ForEachEntity')['rowKey'])}')"
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
                                "body": "${local.slack_message}",
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




