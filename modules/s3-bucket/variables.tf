variable "project_name" {
  description = "Base project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "purpose" {
  description = "Purpose tag value"
  type        = string
}

variable "bucket_name" {
  description = "Custom bucket name (generated if empty)"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days to expire noncurrent versions"
  type        = number
  default     = 7
}