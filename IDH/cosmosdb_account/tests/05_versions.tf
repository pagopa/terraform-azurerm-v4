terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }

  }
}

provider "azurerm" {
  features {}
}

provider "random" {}

resource "random_string" "test" {
  length  = 8
  upper   = false
  lower   = true
  special = false
}
