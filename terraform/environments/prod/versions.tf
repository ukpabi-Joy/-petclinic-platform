terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial backend config — supplied via `terraform init -backend-config=backend.hcl`.
  backend "s3" {}
}

provider "aws" {
  region  = "eu-central-1"
  profile = "default"

  default_tags {
    tags = {
      Project     = "petclinic"
      ManagedBy   = "terraform"
      Environment = "prod"
    }
  }
}
