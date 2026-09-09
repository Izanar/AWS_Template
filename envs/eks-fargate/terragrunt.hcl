include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../src/eks-fargate"
}

inputs = {
  project_name       = "image-test-env"
  environment        = "dev"
  aws_region         = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  vpc_cidr           = "10.10.0.0/16"
  budget_email       = get_env("BUDGET_EMAIL", "")
  monthly_budget_usd = 5
}
