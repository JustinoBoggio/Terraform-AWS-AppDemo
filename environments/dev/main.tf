module "vpc" {
  source = "../../modules/vpc"

  name       = "dev"
  cidr_block = "10.1.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # costo mínimo

  tags = {
    Project = "justino-devops-lab"
    Env     = "dev"
    Owner   = "justino"
  }
}

module "iam_oidc_github" {
  source = "../../modules/iam-oidc-github"

  github_owner = "JustinoBoggio"
  github_repo  = "Terraform-AWS-AppDemo"

  # Permitimos plan en PRs y apply en main
  allowed_refs = ["refs/heads/main", "refs/pull/*/merge"]

  role_name = "gha-terraform-dev"
  # Por ahora, para acelerar dev, usamos PowerUserAccess. Luego endurecemos.
  policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}
