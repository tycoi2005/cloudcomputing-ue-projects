#resource "aws_iam_role" "lambda_exec" {
#  name = "lambda_exec_role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Action    = "sts:AssumeRole"
#      Principal = { Service = "lambda.amazonaws.com" }
#      Effect    = "Allow"
#      Sid       = ""
#    }]
#  })
#}

#resource "aws_iam_role_policy_attachment" "lambda_logging" {
#  role       = aws_iam_role.lambda_exec.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#}

#resource "aws_lambda_function" "api_handler" {
#  function_name = "api-backend"
#  runtime       = "python3.10"
#  role          = aws_iam_role.lambda_exec.arn
#  handler       = "index.lambda_handler"
#  filename      = "${path.module}/lambda.zip"

#  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
#}

resource "aws_lb" "alb" {
  name               = "lambda-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]
}

resource "aws_lb_target_group" "tg" {
  name        = "lambda-tg"
  target_type = "lambda"
  vpc_id      = var.vpc_id

  depends_on = [aws_lambda_function.api_handler]
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg.arn
}

resource "aws_lambda_function" "api_handler" {
  function_name = "api-backend"
  runtime       = "python3.10"
  role          = "arn:aws:iam::637423528848:role/LabRole"
  handler       = "index.lambda_handler"
  filename      = "${path.module}/lambda.zip"

  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
}

resource "aws_lb_target_group_attachment" "lambda_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_lambda_function.api_handler.arn

  depends_on = [aws_lambda_function.api_handler]
}
