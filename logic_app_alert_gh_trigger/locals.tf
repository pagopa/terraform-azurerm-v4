locals {
  custom_action_schema = {
    init_variable = {
      name = "Init status variable"
      body = <<BODY
{
  "type": "InitializeVariable",
  "inputs": {
    "variables": [
      {
        "name": "status",
        "type": "string",
        "value": "active"
      }
    ]
  },
  "runAfter": {
    "Trigger Workflow on Github": [
      "Succeeded"
    ]
  }
}
BODY
    }
    init_conclustion_variable = {
      name = "Init conclustion variable"
      body = <<BODY
{
  "type": "InitializeVariable",
  "inputs": {
    "variables": [
      {
        "name": "conclusion",
        "type": "string",
        "value": "none"
      }
    ]
  },
  "runAfter": {
    "Init status variable": [
      "Succeeded"
    ]
  }
}
BODY
    }
    check_status = {
      name = "Check status"
      body = <<BODY
{
  "type": "Until",
  "expression": "@not(equals(variables('status'),'active'))",
  "limit": {
    "count": 24,
    "timeout": "PT1H"
  },
  "actions": {
    "Delay": {
      "type": "Wait",
      "inputs": {
        "interval": {
          "count": 15,
          "unit": "Second"
        }
      }
    },
    "For_each": {
      "type": "Foreach",
      "foreach": "@outputs('Parse_JSON')?['body']?['workflow_runs']",
      "actions": {
        "Set_variable": {
          "type": "SetVariable",
          "inputs": {
            "name": "status",
            "value": "@item()?['status']"
          }
        },
        "Set_conclusion": {
          "type": "SetVariable",
          "inputs": {
            "name": "conclusion",
            "value": "@item()?['conclusion']"
          },
          "runAfter": {
            "Set_variable": [
              "Succeeded"
            ]
          }
        }
      },
      "runAfter": {
        "Parse_JSON": [
          "Succeeded"
        ]
      }
    },
    "Get_status_of_workflow": {
      "type": "Http",
      "inputs": {
        "uri": "https://api.github.com/repos/${var.github.org}/${var.github.repository}/actions/runs?event=repository_dispatch&per_page=1",
        "method": "GET",
        "headers": {
          "Accept": "application/vnd.github.everest-preview+json",
          "Authorization": "token ${var.github.pat}"
        }
      },
      "runAfter": {
        "Delay": [
          "Succeeded"
        ]
      },
      "runtimeConfiguration": {
        "contentTransfer": {
          "transferMode": "Chunked"
        }
      }
    },
    "Parse_JSON": {
      "type": "ParseJson",
      "inputs": {
        "content": "@body('Get_status_of_workflow')",
        "schema": {
          "properties": {
            "workflow_runs": {
              "items": {
                "properties": {
                  "conclusion": {
                    "type": "string"
                  },
                  "created_at": {
                    "type": "string"
                  },
                  "html_url": {
                    "type": "string"
                  },
                  "id": {
                    "type": "integer"
                  },
                  "status": {
                    "type": "string"
                  }
                },
                "required": [
                  "id",
                  "status",
                  "conclusion",
                  "created_at",
                  "html_url"
                ],
                "type": "object"
              },
              "type": "array"
            }
          },
          "type": "object"
        }
      },
      "runAfter": {
        "Get_status_of_workflow": [
          "Succeeded"
        ]
      }
    }
  },
  "runAfter": {
    "Init conclustion variable": [
      "Succeeded"
    ]
  }
}
BODY
    }
    response = {
      name = "Response"
      body = <<BODY
{
  "type": "If",
  "expression": {
    "and": [
      {
        "equals": [
          "@variables('conclusion')",
          "success"
        ]
      }
    ]
  },
  "actions": {
    "Response_success": {
      "type": "Response",
      "kind": "Http",
      "inputs": {
        "statusCode": 200,
        "body": "@variables('conclusion')"
      }
    }
  },
  "else": {
    "actions": {
      "Response_fail": {
        "type": "Response",
        "kind": "Http",
        "inputs": {
          "statusCode": 500,
          "body": "@variables('conclusion')"
        }
      }
    }
  },
  "runAfter": {
    "Check status": [
      "Succeeded"
    ]
  }
}
BODY
    }
  }
}
