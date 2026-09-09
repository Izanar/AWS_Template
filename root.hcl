# Root Terragrunt configuration
# This file is included by all envs/terragrunt.hcl files

locals {
  # Common settings
  project_name  = "image-test-env"
  environment   = "dev"
  aws_region    = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  budget_email  = get_env("BUDGET_EMAIL", "")
  monthly_budget_usd = 5

  # Remote state configuration (S3 + DynamoDB)
  # Uncomment and configure after creating the S3 bucket and DynamoDB table
  # remote_state_backend = "s3"
  # remote_state_config = {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "${path_relative_to_include()}/terraform.tfstate"
  #   region         = local.aws_region
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# Generate provider block for all modules
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"
}
EOF
}
