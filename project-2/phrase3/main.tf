# =========================
# Phase 3: Decoupled App Infra (with remote state from Phase 2)
# =========================

# === Import Outputs from Phase 2 ===
data "terraform_remote_state" "phase2" {
  backend = "local"

  config = {
    path = "../phrase2/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.phase2.outputs.aws_region
}

# === DB Subnet Group ===
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.phase2.outputs.private_subnet_id_1,
    data.terraform_remote_state.phase2.outputs.private_subnet_id_2,
  ]

  tags = {
    Name = "main-db-subnet-group"
  }
}

# === RDS Instance ===
resource "aws_db_instance" "mysql" {
  identifier             = "app-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [data.terraform_remote_state.phase2.outputs.web_sg_id]
  username               = var.db_user
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
  deletion_protection    = false

  tags = {
    Name = "app-db"
  }
}

# === Secrets Manager ===
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "app-db-secret"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_user,
    password = var.db_password,
    host     = aws_db_instance.mysql.address,
    db       = var.db_name
  })
}

# === Cloud9 Environment ===
resource "aws_cloud9_environment_ec2" "dev" {
  name                         = "app-dev-env"
  instance_type               = "t3.micro"
  subnet_id                   = data.terraform_remote_state.phase2.outputs.public_subnet_ids[0]
  automatic_stop_time_minutes = 30
  image_id                    = "amazonlinux-2-x86_64"

  tags = {
    Environment = "cloud9-dev"
  }

  provisioner "local-exec" {
    command = "aws ssm send-command --document-name 'AWS-RunShellScript' --comment 'Setup Phase 3' --instance-ids $(aws ec2 describe-instances --filters Name=tag:Environment,Values=cloud9-dev --query 'Reservations[].Instances[].InstanceId' --output text) --parameters commands=['bash /home/ec2-user/environment/UserdataScript-phase-3.sh'] --region ${data.terraform_remote_state.phase2.outputs.aws_region}"
  }

  lifecycle {
    ignore_changes = [tags["Name"]]
  }
}

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
