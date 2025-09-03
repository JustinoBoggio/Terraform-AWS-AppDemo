variable "cluster_oidc_issuer_url" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "k8s_namespace" {
  type    = string
  default = "app"
}

variable "k8s_service_account" {
  type    = string
  default = "app-api"
}

variable "secretsmanager_arns" {
  type        = list(string)
  description = "ARNs de secretos a los que dar lectura"
  default     = []
}

variable "s3_bucket_arn" {
  type        = string
  default     = ""
}

variable "s3_prefix" {
  type        = string
  default     = "app/*"
}

variable "tags" {
  type    = map(string)
  default = {}
}
