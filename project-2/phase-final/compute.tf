# final-project/compute.tf

# === Ubuntu AMI Data Source ===
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# === Application Load Balancer (ALB) ===
resource "aws_lb" "main" {
  name               = "${var.naming_prefix}alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "main" {
  name     = "${var.naming_prefix}alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path    = "/"
    matcher = "200"
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

# === EC2 Launch Template ===
resource "aws_launch_template" "web" {
  name_prefix   = "${var.naming_prefix}lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = var.lab_instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_secret_arn = aws_secretsmanager_secret.db_credentials.arn
    aws_region    = var.aws_region
  }))

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_asg_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.naming_prefix}instance"
    }
  }
}

# === EC2 Auto Scaling Group ===
resource "aws_autoscaling_group" "main" {
  name                      = "${var.naming_prefix}asg"
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns         = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

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


# === Cloud9 Development Environment ===
resource "aws_cloud9_environment_ec2" "dev" {
  name          = "${var.naming_prefix}dev-env"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_1.id

  image_id      = "amazonlinux-2-x86_64"
#  connection_type = "CONNECT_SSH"
#  connection_type             = "CONNECT_SSM"
  automatic_stop_time_minutes = 0 # Disable automatic stop

  tags = {
    Environment = "dev"
    Project     = "WebApp-Final"
  }
}