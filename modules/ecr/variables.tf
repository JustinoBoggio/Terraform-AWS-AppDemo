variable "repo_names" {
  description = "Lista de repositorios ECR a crear (p.ej. [\"app-api\", \"app-web\"])"
  type        = list(string)
}

variable "scan_on_push" {
  description = "Habilitar basic image scanning al pushear"
  type        = bool
  default     = true
}

variable "immutability" {
  description = "IMMUTABLE o MUTABLE para tags"
  type        = string
  default     = "IMMUTABLE"
}

variable "lifecycle_keep_last" {
  description = "Cuántas imágenes mantener"
  type        = number
  default     = 20
}

variable "tags" {
  type        = map(string)
  default     = {}
}
