terraform {
  required_providers {

    elasticstack = {
      source  = "elastic/elasticstack"
      version = ">= 0.16.5" #required for jsm integration and artifacts
    }
  }
}
