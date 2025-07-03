variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "The EC2 Key Pair name"
  type        = string
  default = "vockey"
}
