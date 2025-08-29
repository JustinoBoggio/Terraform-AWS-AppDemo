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

  create_provider = true

  github_owner = "JustinoBoggio"
  github_repo  = "Terraform-AWS-AppDemo"

  # Permitimos plan en PRs y apply en main
  allowed_refs = ["refs/heads/main", "refs/pull/*/merge"]

  role_name = "gha-terraform-dev"
  # Por ahora, para acelerar dev, usamos PowerUserAccess. Luego endurecemos.
  policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  ]

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  repo_names          = ["app-api", "app-web"]
  scan_on_push        = true
  immutability        = "IMMUTABLE"
  lifecycle_keep_last = 20

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}


# Role OIDC para la app (build/push)
module "iam_oidc_github_app" {
  source          = "../../modules/iam-oidc-github"
  create_provider = false

  github_owner = "JustinoBoggio"
  github_repo  = "Terraform-AWS-AppDemo"
  allowed_refs = ["refs/heads/main", "refs/tags/*"]
  role_name    = "gha-app-dev"

  policy_arns  = []  # la policy la adjuntamos abajo
  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

data "aws_caller_identity" "this" {}

# Policy mínima para ECR push/pull estricta a TUS repos del módulo ecr
data "aws_iam_policy_document" "ecr_push_min" {
  # Necesario para login a ECR
  statement {
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push/Pull sobre tus repositorios concretos
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories"
    ]
    resources = [
      for name, repo in module.ecr.repositories : repo.arn
    ]
  }
}

resource "aws_iam_policy" "ecr_push_min" {
  name   = "gha-ecr-push-min"
  policy = data.aws_iam_policy_document.ecr_push_min.json
}

resource "aws_iam_role_policy_attachment" "gha_app_ecr_attach" {
  role       = module.iam_oidc_github_app.role_name
  policy_arn = aws_iam_policy.ecr_push_min.arn
}