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