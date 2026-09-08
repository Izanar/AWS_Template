variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "budget_email" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  type    = number
  default = 5
}