variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  default     = "" # Empty in CI/CD
  description = "Optional named profile for local use"
}