terraform {
  required_providers {
    aws = {
      source  = "aws"
      version = "~> 6"
    }

    datadog = {
      source  = "DataDog/datadog"
      version = ">= 3, <5"
    }
  }
}
