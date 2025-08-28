data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_prefix}-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  table_name  = "${var.project_prefix}-tf-lock"
}

resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
}

# Bloqueo total de acceso público
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionado para el tfstate
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación por defecto (SSE-S3) → SIN costo mensual fijo
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # si luego querés KMS: usa aws:kms + KMS key
    }
    bucket_key_enabled = true
  }
}

# Lifecycle para no acumular versiones viejas = ahorrar $
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"

    # Aplica a TODO el bucket (requerido por el provider 5.x)
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_days
    }
  }
}

# DynamoDB lock table (baratísimo en on-demand)
resource "aws_dynamodb_table" "lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
