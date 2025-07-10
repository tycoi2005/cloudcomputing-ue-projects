# =========================
# Phase 3: Decoupled App Infra
# =========================

# === Import Outputs from Phase 2 ===
data "terraform_remote_state" "phase2" {
  backend = "local"

  config = {
    # IMPORTANT: Update this path to be correct relative to your Phase 3 directory
    path = "../phrase2/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.phase2.outputs.aws_region
}

# === DB Security Group ===
# Create a dedicated security group for the database.
resource "aws_security_group" "db_sg" {
  name        = "${var.naming_prefix}db-sg"
  description = "Allow MySQL traffic from the web security group"
  vpc_id      = data.terraform_remote_state.phase2.outputs.vpc_id

  # Ingress Rule: Allow traffic on port 3306 ONLY from the Web Server's SG
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.phase2.outputs.web_sg_id]
  }

    # Ingress Rule 2: Allow traffic from the Public Subnet (where Cloud9 lives)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Note: It's better to get this CIDR from a Phase 2 output,
    # but we know from your code it's 10.0.1.0/24.
    cidr_blocks = ["10.0.1.0/24"]
    description = "Allow traffic from the public subnet for Cloud9 access"
  }

  # Egress can remain open as it's in a private subnet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming_prefix}db-sg"
  }
}

# === DB Subnet Group ===
resource "aws_db_subnet_group" "main" {
  name       = "${var.naming_prefix}main-db-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.phase2.outputs.private_subnet_id_1,
    data.terraform_remote_state.phase2.outputs.private_subnet_id_2,
  ]

  tags = {
    Name = "${var.naming_prefix}main-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.naming_prefix}parameter-group"
  family      = "mysql8.0"
  description = "Custom parameter group with higher connection limit"

  parameter {
    name  = "max_connections"
    value = "200" # A much higher value
  }

  tags = {
    Name = "${var.naming_prefix}parameter-group"
  }
}

# === RDS Instance ===
resource "aws_db_instance" "mysql" {
  identifier             = "${var.naming_prefix}app-db" # Use prefix for unique identifier
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id] # CORRECT: Use the new, secure DB security group

  parameter_group_name   = aws_db_parameter_group.main.name
  
  username               = var.db_user
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false # Per instructions
  deletion_protection    = false

  tags = {
    Name = "${var.naming_prefix}app-db"
  }
}

# === Secrets Manager ===
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.naming_prefix}app-db-secret"
  recovery_window_in_days = 0  # Force immediate deletion
  description            = "Database credentials for the web app"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    user = var.db_user,
    password = var.db_password,
    host     = aws_db_instance.mysql.address,
    db   = aws_db_instance.mysql.db_name,
    engine   = aws_db_instance.mysql.engine,
    port     = aws_db_instance.mysql.port,
    secret_arn = aws_secretsmanager_secret.db_credentials.arn # Add ARN for easy reference
  })

  # Ensure the secret is created only after the RDS instance is available
  depends_on = [aws_db_instance.mysql]
}

# ===  Web Server Instance (Task 5) ===
resource "aws_instance" "web" {
  ami                         = data.terraform_remote_state.phase2.outputs.latest_ubuntu_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = data.terraform_remote_state.phase2.outputs.public_subnet_ids[0] # Use the first public subnet
  vpc_security_group_ids      = [data.terraform_remote_state.phase2.outputs.web_sg_id]
  associate_public_ip_address = true
  key_name                    = data.terraform_remote_state.phase2.outputs.ec2_key_name
  iam_instance_profile        = var.lab_instance_profile_name
  # This profile must allow access to Secrets Manager

  # This user data script installs the app and configures it to use the new secret
  user_data = <<-EOF
              #!/bin/bash

              # Fetch your app install script and run
              # curl -sSL https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-91571/1-lab-capstone-project-1/s3/UserdataScript-phase-3.sh | bash
              apt update -y
              apt install nodejs unzip wget npm mysql-client -y
              #wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-DEV/code.zip -P /home/ubuntu
              wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-91571/1-lab-capstone-project-1/code.zip -P /home/ubuntu
              cd /home/ubuntu
              unzip code.zip -x "resources/codebase_partner/node_modules/*"
              cd resources/codebase_partner
              npm install aws aws-sdk
              export APP_PORT=80
              export DB_SECRET_ARN="${aws_secretsmanager_secret.db_credentials.arn}"
              export AWS_REGION="${data.terraform_remote_state.phase2.outputs.aws_region}"

              CONFIG_FILE="app/config/config.js"

              # Check if file exists
              if [ ! -f "$CONFIG_FILE" ]; then
                  echo "Error: File $CONFIG_FILE not found"
                  exit 1
              fi

              # Backup the original file
              cp "app/config/config.js" "app/config/config.js.bak"

              # Use sed to replace the line
              sed -i 's/const secretName = "Mydbsecret";/const secretName = process.env.DB_SECRET_ARN || "Mydbsecret";/' "app/config/config.js"

              # Check if the replacement was successful
              if grep -q 'const secretName = process.env.DB_SECRET_ARN || "Mydbsecret";' "app/config/config.js"; then
                  echo "File updated successfully"
              else
                  echo "Error: Failed to update the file"
                  # Restore backup if change failed
                  cp "app/config/config.js.bak" "app/config/config.js"
                  exit 1
              fi

              # npm start &
              nohup npm start >> log.txt 2>> log.txt &
              echo '#!/bin/bash -xe
              cd /home/ubuntu/resources/codebase_partner
              export DB_SECRET_ARN="${aws_secretsmanager_secret.db_credentials.arn}"
              export APP_PORT=80
              nohup npm start >> log.txt 2>> log.txt &' > /etc/rc.local
              chmod +x /etc/rc.local

              EOF

  tags = {
    Name = "${var.naming_prefix}web"
  }

  depends_on = [aws_secretsmanager_secret_version.db_credentials_version]
}


# === Cloud9 Environment (Task 3) ===
resource "aws_cloud9_environment_ec2" "dev" {
  name                         = "${var.naming_prefix}app-dev-env"
  instance_type                = "t3.micro"
  subnet_id                    = data.terraform_remote_state.phase2.outputs.public_subnet_ids[0]

  automatic_stop_time_minutes = 0 # Disable automatic stop
  image_id                     = "amazonlinux-2-x86_64"
  tags = {
    Environment = "dev"
    Project     = "WebApp-Phase3"
  }

}

