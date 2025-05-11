terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.3"
    }
  }
}
