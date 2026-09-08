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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_cidr_blocks" {
  description = "CIDR ranges allowed to reach SSH"
  type        = list(string)
  default     = []
}

variable "http_cidr_blocks" {
  description = "CIDR ranges allowed to reach HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR ranges allowed to reach HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "spot" {
  description = "Use Spot instance"
  type        = bool
  default     = true
}