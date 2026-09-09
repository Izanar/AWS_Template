variable "project_name" {
  description = "Base project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
  default     = "1.31"
}

variable "budget_email" {
  description = "Optional email address for the monthly AWS Budget alert"
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Optional AWS Budget threshold in USD"
  type        = number
  default     = 5
}
