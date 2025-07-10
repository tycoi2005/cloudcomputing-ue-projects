# final-project/database.tf

# === RDS Database Parameter Group ===
resource "aws_db_parameter_group" "main" {
  name        = "${var.naming_prefix}parameter-group"
  family      = "mysql8.0"
  description = "Custom parameter group with higher connection limit"

  parameter {
    name  = "max_connections"
    value = "80"
  }
}

# === RDS Database Subnet Group ===
resource "aws_db_subnet_group" "main" {
  name       = "${var.naming_prefix}db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# === RDS Database Instance ===
resource "aws_db_instance" "main" {
  identifier             = "${var.naming_prefix}db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name   = aws_db_parameter_group.main.name
  skip_final_snapshot    = true
  publicly_accessible    = false
}

# === Secrets Manager ===
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.naming_prefix}db-secret"
  recovery_window_in_days = 0 # This will force-delete on 'terraform destroy', do not use in production
  description = "Database credentials for the RDS instance"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    user     = var.db_user
    password = var.db_password
    host     = aws_db_instance.main.address
    db = aws_db_instance.main.db_name
    engine   = aws_db_instance.main.engine
    port     = aws_db_instance.main.port
  })
}