output "gha_role_arn" {
  description = "Role asumido por GitHub Actions"
  value       = module.iam_oidc_github.role_arn
}

output "ecr_repositories" {
  description = "Repos ECR creados"
  value = module.ecr.repositories
}

output "gha_app_role_arn" {
  description = "Role OIDC para build/push"
  value       = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/gha-app-dev"
}