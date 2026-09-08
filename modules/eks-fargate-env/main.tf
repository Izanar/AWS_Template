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

  fargate_profiles = {
    weather_demo = {
      name = "weather-demo"
      selectors = [{
        namespace = "weather-demo"
      }]
      subnet_ids = module.vpc.private_subnets
    }
    ingress_nginx = {
      name = "ingress-nginx"
      selectors = [{
        namespace = "ingress-nginx"
      }]
      subnet_ids = module.vpc.private_subnets
    }
  }
}

module "budget" {
  source           = "../budget"
  project_name     = var.project_name
  environment      = var.environment
  budget_email     = var.budget_email
  monthly_budget_usd = var.monthly_budget_usd
  suffix           = "fargate"
}