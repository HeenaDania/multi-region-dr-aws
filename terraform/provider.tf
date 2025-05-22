terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Configure backend for state management
  backend "s3" {
    bucket         = "terraform-state-multi-region-dr"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Default provider configuration (primary region)
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

# Secondary region provider
provider "aws" {
  region = "us-west-2"
  alias  = "secondary"
}
