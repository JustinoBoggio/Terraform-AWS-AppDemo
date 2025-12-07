data "aws_caller_identity" "current" {}

locals {
  oidc_host = replace(var.cluster_oidc_issuer_url, "https://", "")
  sa_sub    = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
}

data "aws_iam_policy_document" "eso_trust" {
  statement {
    sid     = "IRSA"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = [local.sa_sub]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Minimal policy for Secret manager access
data "aws_iam_policy_document" "eso" {
  statement {
    sid     = "DescribeList"
    effect  = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "GetSecretValue"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = length(var.allowed_secret_arns) > 0 ? var.allowed_secret_arns : ["*"]
  }
}

resource "aws_iam_policy" "eso" {
  name   = "${var.role_name}-secretsmanager"
  policy = data.aws_iam_policy_document.eso.json
  tags   = var.tags
}

resource "aws_iam_role" "eso" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "eso_attach" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}
