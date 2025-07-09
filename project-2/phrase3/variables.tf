variable "db_user" {
    type= string
    default = "nodeapp"
    description = "Database username"
}
variable "db_password" {
    type = string
    default = "student12"
    description = "Database password"
}

variable "db_name" {
    type = string
    default = "STUDENTS"
    description = "Database name"
}

variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources."
  default     = "tf-pj2-ph3-"
}

variable "lab_instance_profile_name" {
  description = "The name of the IAM instance profile (e.g., LabInstanceProfile) that allows access to Secrets Manager."
  type        = string
  default     = "LabInstanceProfile" #
}