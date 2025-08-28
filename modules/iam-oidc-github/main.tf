locals {
  repo_full = "repo:${var.github_owner}/${var.github_repo}"
  sub_patterns = [
    for r in var.allowed_refs : "${local.repo_full}:ref:${r}"
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
  # Desde las versiones recientes del provider AWS, ya no es necesario setear thumbprint_list manualmente.
  # Referencia: Terraform Registry indica que si no se provee, IAM lo resuelve automáticamente.
}

data "aws_iam_openid_connect_provider" "github" {
  arn = coalesce(
    try(aws_iam_openid_connect_provider.github[0].arn, null),
    "arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/token.actions.githubusercontent.com"
  )
}

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.sub_patterns
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  max_session_duration = 3600
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.gha.name
  policy_arn = each.value
}
