terraform {
  required_providers {

    elasticstack = {
      source  = "elastic/elasticstack"
      version = "~> 0.16" #required for jsm integration
    }
  }
}
