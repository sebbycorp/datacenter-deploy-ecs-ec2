terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    consul = {
      source = "hashicorp/consul"
      version = "2.17.0"
    }
  }

}
