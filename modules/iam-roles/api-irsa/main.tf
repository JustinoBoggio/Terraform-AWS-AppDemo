locals {
  clean_prefix  = trim(var.s3_prefix, "/")               # ej: "app"  o "" (raíz)
  object_suffix  = local.clean_prefix != "" ? "/${local.clean_prefix}/*" : "/*"
  bucket_arn     = var.s3_bucket_arn
  objects_arn   = local.clean_prefix != "" ? "${var.s3_bucket_arn}/${local.clean_prefix}/*" : "${var.s3_bucket_arn}/*"
}

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

# Policy mínima SOLO S3 (la app NO lee Secrets Manager si usás ESO)
data "aws_iam_policy_document" "app" {
  # ListBucket: solo bucket ARN
  statement {
    sid     = "ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [var.s3_bucket_arn]

    # (opcional) limitar listado a un prefijo
    # condition {
    #   test     = "StringLike"
    #   variable = "s3:prefix"
    #   values   = [local.clean_prefix != "" ? "${local.clean_prefix}/*" : "*"]
    # }
  }
  # RW en objetos: solo objetos bajo el prefijo
  statement {
    sid     = "RWObjects"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [local.objects_arn]
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