# === Outputs ===
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.address
}

output "secret_arn" {
  description = "ARN of the DB credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "cloud9_url" {
  description = "Cloud9 environment ID (used to open in AWS Console)"
  value       = aws_cloud9_environment_ec2.dev.id
}

output "new_web_server_public_ip" {
  description = "Public IP of the new web server"
  value       = aws_instance.web.public_ip
}

output "db_sg_id" {
  description = "The ID of the security group for the RDS database."
  value       = aws_security_group.db_sg.id
}

output "lab_instance_profile_name" {
  description = "The name of the IAM instance profile used by the web server."
  value       = var.lab_instance_profile_name
}