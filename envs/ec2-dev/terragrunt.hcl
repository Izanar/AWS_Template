include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../src/ec2-dev"
}

inputs = {
  project_name      = "image-test-env"
  environment       = "dev"
  aws_region        = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  instance_type     = "t3.micro"
  public_key_path   = "~/.ssh/id_rsa.pub"
  ssh_cidr_blocks   = []
  http_cidr_blocks  = ["0.0.0.0/0"]
  https_cidr_blocks = ["0.0.0.0/0"]
  spot              = true
  budget_email      = get_env("BUDGET_EMAIL", "")
  monthly_budget_usd = 5
}
