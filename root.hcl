# Root Terragrunt configuration
# This file is included by all envs/terragrunt.hcl files

locals {
  # Common settings
  project_name       = "aws-template"
  environment        = "dev"
  aws_region         = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  budget_email       = get_env("BUDGET_EMAIL", "")
  monthly_budget_usd = 5

  # Optional existing backend. No bucket or lock table is created by this template.
  state_bucket = get_env("TF_STATE_BUCKET", "")
  state_region = get_env("TF_STATE_REGION", local.aws_region)
  lock_table   = get_env("TF_LOCK_TABLE", "")
  local_only   = path_relative_to_include() == "envs/local-wsl"
}

# Persist local state outside the disposable Terragrunt cache.
generate "backend" {
  path              = "backend.tf.json"
  if_exists         = "overwrite"
  disable_signature = true
  contents = local.state_bucket != "" && !local.local_only ? jsonencode({
    terraform = { backend = { s3 = {
      bucket         = local.state_bucket
      key            = "aws-template/${local.aws_region}/${path_relative_to_include()}/terraform.tfstate"
      region         = local.state_region
      encrypt        = true
      dynamodb_table = local.lock_table
    } } }
    }) : jsonencode({
    terraform = { backend = { local = {
      path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
    } } }
  })
}

# Generate provider block for all modules
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.local_only ? "terraform { required_version = \">= 1.9.0\" }\n" : <<EOF
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${path_relative_to_include() == "envs/ec2" ? "~> 6.0" : "~> 5.95"}"
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
