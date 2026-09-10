output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "url" {
  description = "Application URL"
  value       = "http://${aws_instance.web.public_ip}"
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
