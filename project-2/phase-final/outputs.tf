# final-project/outputs.tf

output "application_url" {
  description = "The public URL for the load-balanced web application."
  value       = "http://${aws_lb.main.dns_name}"
}

output "rds_endpoint" {
  description = "The endpoint address of the RDS database instance."
  value       = aws_db_instance.main.address
}


output "database_secret_arn" {
  description = "The ARN of the secret containing the database credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "cloud9_url" {
  description = "The endpoint address of the RDS database instance."
  value       = aws_cloud9_environment_ec2.dev.id
}