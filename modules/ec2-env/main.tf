module "ec2_webserver" {
  source            = "../ec2-webserver"
  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  instance_type     = var.instance_type
  public_key_path   = var.public_key_path
  ssh_cidr_blocks   = var.ssh_cidr_blocks
  http_cidr_blocks  = var.http_cidr_blocks
  https_cidr_blocks = var.https_cidr_blocks
  spot              = var.spot
}

module "budget" {
  source           = "../budget"
  project_name     = var.project_name
  environment      = var.environment
  budget_email     = var.budget_email
  monthly_budget_usd = var.monthly_budget_usd
  suffix           = "ec2"
}