output "gha_role_arn" {
  description = "Role asumido por GitHub Actions"
  value       = module.iam_oidc_github.role_arn
}

output "ecr_repositories" {
  description = "Repos ECR creados"
  value       = module.ecr.repositories
}

output "gha_app_role_arn" {
  description = "Role OIDC para build/push"
  value       = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/gha-app-dev"
}

output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "IRSA_role_arn" {
  description = "Role IRSA para la app API"
  value       = module.irsa_app_api.role_arn
}

output "eso_role_arn" {
  value = module.iam_irsa_eso.role_arn
}

output "grafana_port_forward" {
  value = module.observability.grafana_port_forward
}

output "prometheus_url_hint" {
  value = module.observability.prometheus_url_hint
}