variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  default     = "" # vacío en CI; en local podés setear tf-admin
  description = "Optional named profile for local use"
}