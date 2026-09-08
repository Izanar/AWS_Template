variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "http_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "spot" {
  type    = bool
  default = true
}

variable "budget_email" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  type    = number
  default = 5
}