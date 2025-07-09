variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_id" {}
variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources."
  default     = "tf-pj1-"
}