variable "project_prefix" {
  description = "Prefijo para nombrar recursos de bootstrap"
  type        = string
  default     = "tf-justino"
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil AWS CLI para el provider local"
  type        = string
  default     = "tf-admin"
}

variable "noncurrent_days" {
  description = "Días para expirar versiones antiguas del state y ahorrar costos"
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Permitir borrar el bucket aunque tenga objetos (útil en labs)"
  type        = bool
  default     = false
}
