variable "aws_region" {
  description = "The AWS region to deploy all resources in."
  type        = string
  default     = "us-east-1"
}

variable "naming_prefix" {
  description = "A consistent prefix for all resource names."
  type        = string
  default     = "tf-pj2-final-"
}

variable "key_name" {
  description = "The name of the EC2 Key Pair for SSH access."
  type        = string
  default     = "vockey"
}

variable "lab_instance_profile_name" {
  description = "The name of the IAM instance profile that allows EC2 to access Secrets Manager."
  type        = string
  default     = "LabInstanceProfile"
}

variable "db_name" {
  description = "The name of the database to create in RDS."
  type        = string
  default     = "STUDENTS"
}

variable "db_user" {
  description = "The master username for the RDS database."
  type        = string
  sensitive   = true
  default     = "nodeapp"
}

variable "db_password" {
  description = "The master password for the RDS database."
  type        = string
  sensitive   = true
  default = "student12"
}