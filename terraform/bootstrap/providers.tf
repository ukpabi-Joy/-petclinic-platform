terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Bootstrap intentionally uses local state: it creates the S3 bucket and
  # DynamoDB table that every other environment uses as a remote backend.
}

provider "aws" {
  region  = "eu-central-1"
  profile = "default"

  default_tags {
    tags = {
      Project   = "petclinic"
      ManagedBy = "terraform"
    }
  }
}
