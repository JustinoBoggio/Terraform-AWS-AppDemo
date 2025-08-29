output "gha_role_arn" {
  description = "Role asumido por GitHub Actions"
  value       = module.iam_oidc_github.role_arn
}