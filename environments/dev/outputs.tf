output "gha_role_arn" {
  description = "Role ARN assumed by GitHub Actions for Infra Provisioning"
  value       = module.iam_oidc_github.role_arn
}

output "ecr_repositories" {
  description = "Created ECR repository URLs"
  value       = module.ecr.repositories
}

output "gha_app_role_arn" {
  description = "Role ARN for application CI/CD (Build & Push)"
  value       = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/gha-app-dev"
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}