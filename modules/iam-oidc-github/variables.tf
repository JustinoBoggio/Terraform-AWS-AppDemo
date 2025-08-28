variable "create_provider" {
  description = "Crear el OIDC provider de GitHub en esta cuenta"
  type        = bool
  default     = true
}

variable "github_owner" { type = string }
variable "github_repo"  { type = string }

variable "allowed_refs" {
  description = "Lista de refs permitidas (ej: refs/heads/main, refs/pull/*/merge)"
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "role_name" {
  description = "Nombre del role a crear para GHA"
  type        = string
  default     = "gha-terraform-dev"
}

variable "policy_arns" {
  description = "Managed policy ARNs a adjuntar al role (temporalmente PowerUser en dev)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
}
