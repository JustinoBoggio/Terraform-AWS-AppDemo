variable "aws_region" {
  type = string
}

variable "cluster_oidc_issuer_url" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "service_account_namespace" {
  type    = string
  default = "external-secrets"
}

variable "service_account_name" {
  type    = string
  default = "external-secrets"
}

variable "allowed_secret_arns" {
  type    = list(string)
  default = []
}

variable "role_name" {
  type    = string
  default = "eso-controller-dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}
