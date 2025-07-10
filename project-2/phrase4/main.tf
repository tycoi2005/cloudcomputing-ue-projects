# phase4/main.tf

# =========================
# Phase 4: High Availability & Scalability
# =========================

data "terraform_remote_state" "phase2" {
  backend = "local"
  config = {
    path = "../phrase2/terraform.tfstate"
  }
}

data "terraform_remote_state" "phase3" {
  backend = "local"
  config = {
    path = "../phrase3/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.phase2.outputs.aws_region
}

# === Security Group for the Load Balancer ===
resource "aws_security_group" "alb_sg" {
  name        = "${var.naming_prefix}alb-sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = data.terraform_remote_state.phase2.outputs.vpc_id

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

  tags = {
    Name = "${var.naming_prefix}alb-sg"
  }
}

# === Security Group for the Web Servers ===
# This group allows traffic from the ALB and allows the servers to talk to the DB
resource "aws_security_group" "web_asg_sg" {
  name        = "${var.naming_prefix}web-asg-sg"
  description = "Allow HTTP from ALB and SSH"
  vpc_id      = data.terraform_remote_state.phase2.outputs.vpc_id

  # Allow HTTP traffic ONLY from the Application Load Balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow SSH from anywhere (for troubleshooting)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming_prefix}web-asg-sg"
  }
}

# === Application Load Balancer (ALB) ===
resource "aws_lb" "main" {
  name               = "${var.naming_prefix}alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.phase2.outputs.public_subnet_ids

  tags = {
    Name = "${var.naming_prefix}alb"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.naming_prefix}alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.phase2.outputs.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# This adds a rule to the DB Security Group from Phase 3, allowing
# traffic from our new ASG Security Group.
resource "aws_security_group_rule" "allow_asg_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.phase3.outputs.db_sg_id
  source_security_group_id = aws_security_group.web_asg_sg.id
  description              = "Allow traffic from Phase 4 ASG instances"
}

# === EC2 Launch Template ===
resource "aws_launch_template" "web" {
  name_prefix = "${var.naming_prefix}web-lt-"
  image_id      = data.terraform_remote_state.phase2.outputs.latest_ubuntu_ami_id
  instance_type = "t3.micro"
  key_name      = data.terraform_remote_state.phase2.outputs.ec2_key_name

  iam_instance_profile {
    name = data.terraform_remote_state.phase3.outputs.lab_instance_profile_name
  }

  # Render the user_data script, passing in our secret ARN and region
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_secret_arn = data.terraform_remote_state.phase3.outputs.secret_arn
    aws_region    = data.terraform_remote_state.phase2.outputs.aws_region
  }))

  # Ensures new instances get a public IP
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [
        aws_security_group.web_asg_sg.id
    ]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.naming_prefix}web-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# === EC2 Auto Scaling Group ===
resource "aws_autoscaling_group" "main" {
  name                = "${var.naming_prefix}asg"
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = data.terraform_remote_state.phase2.outputs.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"

  health_check_grace_period = 600 # In seconds. Gives instances 10 minutes to start up.
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

# === Auto Scaling Policy ===
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.naming_prefix}cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 20.0
  }
}

