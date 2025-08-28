output "oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
  value = aws_iam_role.gha.arn
}
