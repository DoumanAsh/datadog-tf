terraform {
  required_providers {
    helm = {
      source  = "helm"
      version = ">= 3, <4"
    }
  }
}
