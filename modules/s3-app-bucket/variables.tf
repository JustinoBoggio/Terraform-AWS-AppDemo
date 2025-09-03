variable "name" {
  type        = string
  description = "Nombre del bucket S3"
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