include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../src/eks-ec2-s3-dev"
}

inputs = {
  project_name       = "image-test-env"
  environment        = "dev"
  aws_region         = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  vpc_cidr           = "10.10.0.0/16"
  node_instance_types = ["t3.small", "t3a.small"]
  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 3
  node_capacity_type  = "SPOT"
  force_destroy_bucket = true
  budget_email       = get_env("BUDGET_EMAIL", "")
  monthly_budget_usd = 5
}
