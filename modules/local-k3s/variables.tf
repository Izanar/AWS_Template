variable "kubernetes_version" {
  description = "k3s version"
  type        = string
  default     = "v1.31.1+k3s1"
}

variable "node_port" {
  description = "NodePort for nginx service"
  type        = number
  default     = 30080
}