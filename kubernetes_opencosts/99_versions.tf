terraform {
  required_version = ">= 1.9.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "<= 2.33.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
  }
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}
