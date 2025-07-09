resource "aws_lambda_function" "api_handler" {
  function_name = "${var.naming_prefix}-api-backend"
  runtime       = "python3.10"
  role          = "arn:aws:iam::637423528848:role/LabRole"
  handler       = "index.lambda_handler"
  filename      = "${path.module}/lambda.zip"

  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
}


resource "aws_lb" "alb" {
  name               = "${var.naming_prefix}-lambda-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]
}

resource "aws_lb_target_group" "tg" {
  name        = "lambda-tg"
  target_type = "lambda"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Method Not Allowed"
      status_code  = "405"
    }
  }
}

resource "aws_lb_listener_rule" "allow_post" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    http_request_method {
      values = ["POST"]
    }
  }
}

# This permission allows the ALB to invoke the Lambda function.
resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg.arn
}

# This resource attaches the Lambda to the target group.
resource "aws_lb_target_group_attachment" "lambda_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_lambda_function.api_handler.arn

  # FIX: Explicitly depend on the permission resource to avoid a race condition.
  depends_on = [
    aws_lambda_permission.allow_alb
  ]
}