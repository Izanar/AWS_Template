variable "project_name" {
  description = "Base project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "budget_email" {
  description = "Email address for budget alert (empty = no budget)"
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Monthly budget threshold in USD"
  type        = number
  default     = 5
}

variable "suffix" {
  description = "Optional suffix for budget name (e.g., 'ec2', 'fargate', 's3')"
  type        = string
  default     = ""
}