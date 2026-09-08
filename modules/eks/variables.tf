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

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_endpoint" {
  description = "Public EKS API endpoint"
  type        = bool
  default     = true
}

variable "use_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = false
}

variable "install_ingress_nginx" {
  description = "Install NGINX Ingress Controller via Helm"
  type        = bool
  default     = true
}

variable "ingress_nginx_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.11.2"
}

variable "fargate_profiles" {
  description = "Fargate profiles map"
  type        = any
  default     = {}
}

variable "managed_node_groups" {
  description = "Managed node groups map"
  type        = any
  default     = {}
}