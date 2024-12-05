terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~> 1.12"
    }
  }
}

data "azurerm_subscription" "current" {}
