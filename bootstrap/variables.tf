variable "project_prefix" {
  description = "Prefix for bootstrap resources naming"
  type        = string
  default     = "tf-justino"
}

variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for local execution"
  type        = string
  default     = "tf-admin"
}

variable "noncurrent_days" {
  description = "Days to retain non-current state versions (Cost Optimization)"
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Allow bucket destruction even if not empty (Useful for labs)"
  type        = bool
  default     = false
}