variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "The EC2 Key Pair name"
  type        = string
  default = "vockey"
}

variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources."
  default     = "tf-pj2-ph2-"
}