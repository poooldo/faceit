terraform {
  required_version = "~> 1.4"

  backend "s3" {
    bucket  = "faceit-hw-tfstates"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    profile = "mytf"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "mytf"
}
