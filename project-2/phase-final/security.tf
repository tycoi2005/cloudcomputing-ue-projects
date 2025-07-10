# final-project/security.tf

# === Security Group for the Load Balancer ===
resource "aws_security_group" "alb_sg" {
  name        = "${var.naming_prefix}alb-sg"
  description = "Allow HTTP traffic to the ALB from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# === Security Group for the Web Servers (in the ASG) ===
resource "aws_security_group" "web_asg_sg" {
  name        = "${var.naming_prefix}web-asg-sg"
  description = "Allow HTTP from ALB and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only allows traffic from our ALB
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH for troubleshooting
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# === Security Group for the Cloud9 Dev Environment ===
resource "aws_security_group" "cloud9_sg" {
  name   = "${var.naming_prefix}cloud9-sg"
  vpc_id = aws_vpc.main.id


  # AWS manages ingress/egress for Cloud9 SSH connections,
  # but we can add egress rules if needed.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows access from any IP address
    description = "Allow SSH for Cloud9 connection"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# === Security Group for the RDS Database ===
resource "aws_security_group" "db_sg" {
  name        = "${var.naming_prefix}db-sg"
  description = "Allow MySQL traffic from web servers and Cloud9"
  vpc_id      = aws_vpc.main.id

  # Rule 1: Allow traffic from the Auto Scaling Group web servers
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_asg_sg.id]
  }

  # Rule 2: Allow traffic from the Cloud9 environment for admin/migration
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.cloud9_sg.id]
  }

  ingress {
    description = "Allow MySQL from Cloud9 subnet"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public_1.cidr_block]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}