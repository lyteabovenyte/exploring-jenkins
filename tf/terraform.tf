terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                  = var.region
#   shared_credentials_file = var.shared_credentials_file
  profile                 = var.aws_profile
}