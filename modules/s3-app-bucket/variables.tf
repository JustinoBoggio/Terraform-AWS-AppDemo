variable "name" {
  type        = string
  description = "S3 bucket name"
}

variable "force_destroy" {
  type        = bool
  default     = false
}

variable "versioning" {
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
}