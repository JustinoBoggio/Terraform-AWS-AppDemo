data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "irsa-${var.k8s_namespace}-${var.k8s_service_account}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# Policy: leer secretos específicos + R/W en un prefijo de S3
data "aws_iam_policy_document" "app" {
  dynamic "statement" {
    for_each = length(var.secretsmanager_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = var.secretsmanager_arns
    }
  }

  dynamic "statement" {
    for_each = var.s3_bucket_arn != "" ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = concat(
        [var.s3_bucket_arn],
        ["${var.s3_bucket_arn}/${var.s3_prefix}"]
      )
    }
  }
}

resource "aws_iam_policy" "app" {
  name   = "irsa-${var.k8s_namespace}-${var.k8s_service_account}"
  policy = data.aws_iam_policy_document.app.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.app.arn
}