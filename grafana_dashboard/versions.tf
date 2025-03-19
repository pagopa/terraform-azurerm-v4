terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3"
    }
  }
}
