variable "db_name" {
  type        = string
  default     = "appdb"
}

variable "engine_version" {
  type        = string
  default     = "15.12"
}

variable "instance_class" {
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage_gb" {
  type        = number
  default     = 20
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs para el DB subnet group"
}

variable "vpc_id" {
  type        = string
}

variable "allowed_sg_ids" {
  type        = list(string)
  description = "Security Group IDs autorizados a acceder (ej: node SG de EKS)"
}

variable "backup_retention_days" {
  type        = number
  default     = 3
}

variable "skip_final_snapshot" {
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
}
