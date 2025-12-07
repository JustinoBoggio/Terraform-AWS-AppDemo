data "aws_caller_identity" "current" {}

# ---------------------------------------------------------
# NETWORKING (VPC)
# ---------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name       = "dev"
  cidr_block = "10.1.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Cost optimized for dev environment

  tags = {
    Project = "justino-devops-lab"
    Env     = "dev"
    Owner   = "justino"
  }
}

# ---------------------------------------------------------
# IDENTITY & SECURITY (OIDC)
# ---------------------------------------------------------
module "iam_oidc_github" {
  source = "../../modules/iam-oidc-github"

  create_provider = true

  github_owner = "JustinoBoggio"
  github_repo  = "Terraform-AWS-AppDemo"

  # Allow Plan on PRs and Apply on Main
  allowed_refs = [
    "refs/heads/main",             # Push/Dispatch to main
    "refs/heads/*",                # Feature branches
    "refs/pull/*/merge",           # Standard PR merge ref
    "refs/pull/*/head",            # Standard PR head ref
    "refs/tags/*",                 # Releases
    "environment:dev"              # Github Environment
  ]

  role_name = "gha-terraform-dev"
  
  # Using broad permissions for the lab. In prod, scope this down.
  policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess" 
  ]

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

# ---------------------------------------------------------
# CONTAINER REGISTRY (ECR)
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# IAM POLICIES FOR CI/CD
# ---------------------------------------------------------

# Policy: ECR Push/Pull scoped to specific repos
data "aws_iam_policy_document" "ecr_push_min" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

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

# Policy: EKS Describe
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

# ---------------------------------------------------------
# COMPUTE (EKS CLUSTER)
# ---------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1" 

  cluster_name    = "dev-eks"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] 

  enable_irsa = true

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # Node Group (Spot Instances for Cost Optimization)
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

  # Cluster Access (RBAC)
  access_entries = {
    tf_admin = {
      # Replaced hardcoded ID with dynamic account ID
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/tf-admin"
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

# ---------------------------------------------------------
# DATA (RDS & S3)
# ---------------------------------------------------------
module "s3_app" {
  source = "../../modules/s3-app-bucket"

  name          = "justi-app-dev-${data.aws_caller_identity.current.account_id}"
  force_destroy = true 
  versioning    = true

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  db_name              = "appdb"
  engine_version       = "15.12"
  instance_class       = "db.t4g.micro"
  allocated_storage_gb = 20

  subnet_ids     = module.vpc.private_subnet_ids
  vpc_id         = module.vpc.vpc_id
  allowed_sg_ids = [module.eks.node_security_group_id]

  backup_retention_days = 3
  skip_final_snapshot   = true

  tags = {
    Project     = "devops-lab"
    Environment = "dev"
    Owner       = "justino"
  }
}

# Store DB Credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db" {
  name = "dev/app/db"
  tags = {
    Project     = "devops-lab"
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = module.rds_postgres.endpoint
    port     = module.rds_postgres.port
    dbname   = "appdb"
    username = module.rds_postgres.username
    password = module.rds_postgres.password
  })
}