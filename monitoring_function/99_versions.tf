terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3"
    }
  }
}

provider "grafana" {
  alias = "cloud"

  url  = var.grafana_url
  auth = var.grafana_api_key
}
