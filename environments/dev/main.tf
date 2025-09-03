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
  allowed_refs = [
    "refs/heads/main",               # push / workflow_dispatch en main
    "refs/heads/*",                  # ramas feature/*
    "refs/pull/*/merge",             # PR común
    "refs/pull/*/head",              # PR con head (algunas acciones)
    "refs/tags/*",                   # releases
    "environment:dev",               # entorno dev en main                          
    "refs/heads/gh-readonly-queue/*" # merge queue (si lo usás)
  ]

  role_name = "gha-terraform-dev"
  # Por ahora, para acelerar dev, usamos PowerUserAccess. Luego endurecemos.
  policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess" # <- temporal para crear roles/adjuntar policies/PassRole
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

  policy_arns = [] # la policy la adjuntamos abajo
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
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
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
      "ecr:DescribeImages",
      "ecr:ListImages",
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

data "aws_iam_policy_document" "eks_describe_cluster" {
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_describe_cluster" {
  name   = "gha-eks-describe-cluster"
  policy = data.aws_iam_policy_document.eks_describe_cluster.json
}

resource "aws_iam_role_policy_attachment" "gha_app_eks_attach" {
  role       = module.iam_oidc_github_app.role_name
  policy_arn = aws_iam_policy.eks_describe_cluster.arn
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1" # fíjalo; luego bump controlado

  cluster_name    = "dev-eks"
  cluster_version = "1.30"

  # Networking (de tu módulo VPC)
  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # en dev; luego tu IP /32

  enable_irsa = true

  # Logs de control plane (baratos y útiles)
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  # Node group Spot barato (t3.small). Ajusta a ARM si te conviene (t4g.small)
  eks_managed_node_groups = {
    dev = {
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      min_size     = 0
      desired_size = 1
      max_size     = 2
      disk_size    = 20

      subnet_ids = module.vpc.private_subnet_ids
      labels = {
        env = "dev"
      }
      tags = {
        Name = "dev-ng"
      }
    }
  }
  access_entries = {
    gha-app = {
      principal_arn = module.iam_oidc_github_app.role_arn

      # Otorga permisos de admin a nivel CLUSTER
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    tf-admin = {
      principal_arn = "arn:aws:iam::215873709989:user/tf-admin"
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

module "s3_app" {
  source = "../../modules/s3-app-bucket"

  name          = "justi-app-dev-${data.aws_caller_identity.this.account_id}"
  force_destroy = true   # dev: para poder destruir sin vaciar a mano
  versioning    = true

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  db_name               = "appdb"
  engine_version        = "15.8"
  instance_class        = "db.t4g.micro"
  allocated_storage_gb  = 20

  subnet_ids            = module.vpc.private_subnet_ids
  vpc_id                = module.vpc.vpc_id
  allowed_sg_ids        = [module.eks.node_security_group_id]

  backup_retention_days = 3
  skip_final_snapshot   = true

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

resource "aws_secretsmanager_secret" "db" {
  name = "dev/app/db"
  tags = {
    Project     = "devops-lab"
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = module.rds_postgres.endpoint
    port     = module.rds_postgres.port
    dbname   = "appdb"
    username = module.rds_postgres.username
    password = module.rds_postgres.password
  })
}

module "irsa_app_api" {
  source = "../../modules/iam-roles/api-irsa"

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn

  k8s_namespace           = "app"
  k8s_service_account     = "app-api"

  secretsmanager_arns     = [aws_secretsmanager_secret.db.arn]
  s3_bucket_arn           = module.s3_app.bucket_arn
  s3_prefix               = "app/*"

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}
