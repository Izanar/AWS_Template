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

variable "node_instance_types" {
  description = "EKS managed node group instance types"
  type        = list(string)
  default     = ["t3.small", "t3a.small"]
}

variable "node_desired_size" {
  description = "EKS managed node group desired size"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "EKS managed node group minimum size"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "EKS managed node group maximum size"
  type        = number
  default     = 3
}

variable "node_capacity_type" {
  description = "EKS managed node group capacity type"
  type        = string
  default     = "SPOT"
}

variable "force_destroy_bucket" {
  description = "Allow the audio S3 bucket to be destroyed even when non-empty"
  type        = bool
  default     = true
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
