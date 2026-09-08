module "vpc" {
  source          = "../vpc"
  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  cidr            = var.vpc_cidr
}

module "eks" {
  source       = "../eks"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  install_ingress_nginx = true
  public_endpoint       = true
  use_irsa              = true

  managed_node_groups = {
    default = {
      name           = "default"
      instance_types = var.node_instance_types
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      capacity_type  = var.node_capacity_type
    }
  }
}

module "s3_audio" {
  source       = "../s3-bucket"
  project_name = var.project_name
  environment  = var.environment
  purpose      = "audio"
  force_destroy = var.force_destroy_bucket
}

module "cloudfront_audio" {
  source                        = "../cloudfront-oac"
  project_name                  = var.project_name
  environment                   = var.environment
  purpose                       = "audio"
  s3_bucket_id                  = module.s3_audio.bucket_id
  s3_bucket_arn                 = module.s3_audio.bucket_arn
  s3_bucket_regional_domain_name = module.s3_audio.bucket_regional_domain_name
  s3_prefix                     = "audio/"
}

module "budget" {
  source           = "../budget"
  project_name     = var.project_name
  environment      = var.environment
  budget_email     = var.budget_email
  monthly_budget_usd = var.monthly_budget_usd
  suffix           = "s3"
}