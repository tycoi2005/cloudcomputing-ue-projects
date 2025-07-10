# phase4/variables.tf

variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all Phase 4 resources."
  default     = "tf-pj2-p4-"
}