locals {
  policy_keep_last = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last N images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.lifecycle_keep_last
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repo_names)

  name                 = each.key
  image_tag_mutability = var.immutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256" # sin KMS para no sumar costos
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "keep_last" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name
  policy     = local.policy_keep_last
}
