output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "app_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the app password"
  value       = aws_secretsmanager_secret.app_password.arn
}

output "app_password" {
  description = "Generated application password (stored in Secrets Manager)"
  value       = random_password.app_password.result
  sensitive   = true
}
