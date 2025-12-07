variable "repo_names" {
  description = "List of ECR repository names to create (e.g. [\"app-api\", \"app-web\"])"
  type        = list(string)
}

variable "scan_on_push" {
  description = "Enable basic image scanning on push"
  type        = bool
  default     = true
}

variable "immutability" {
  description = "Image tag mutability setting (IMMUTABLE or MUTABLE)"
  type        = string
  default     = "IMMUTABLE"
}

variable "lifecycle_keep_last" {
  description = "Number of most recent images to retain (Lifecycle Policy)"
  type        = number
  default     = 20
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}