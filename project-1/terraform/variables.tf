variable "aws_region" {
  type        = string
  description = "AWS region to use for resources."
  default     = "us-east-1"
}

variable "bucket_name_primary" {
  type        = string
  description = "Name of the S3 Bucket"
  default     = "cf-s3-static-banana-primary"
}

variable "bucket_name_failover" {
  type        = string
  description = "Name of the S3 Bucket"
  default     = "cf-s3-static-banana-failover"
}

variable "company" {
  type        = string
  description = "Company name for resource tagging"
  default     = "CT"
}

variable "project" {
  type        = string
  description = "Project name for resource tagging"
  default     = "Project"
}

variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources."
  default     = "Demo"
}

variable "environment" {
  type        = string
  description = "Environment for deployment"
  default     = "dev"
}

variable "instance_key" {
  default = "WorkshopKeyPair"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to use for ALB and related networking"
  default     = "vpc-0eb129b6ea5755e0c"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for ALB"
  default     = [
    "subnet-09ba79a5554d2125a", # us-east-1b
    "subnet-03ea5e039bf269e79", # us-east-1a
    "subnet-09402eaff58dc84c4", # us-east-1f
    "subnet-0dcf5d3c19816dd7c", # us-east-1c
    "subnet-0cf004a2d2d8b6d05", # us-east-1e
    "subnet-0e3a5d6ab19900e4e"  # us-east-1d
  ]
}
