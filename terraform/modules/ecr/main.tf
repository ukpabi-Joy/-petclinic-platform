locals {
  # Repository names follow petclinic-dev/{service} and petclinic-prod/{service}.
  prefix = "${var.project}-${var.environment}"

  repositories = { for svc in var.services : svc => "${local.prefix}/${svc}" }
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name                 = each.value
  image_tag_mutability = var.tag_mutability
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Customer-managed KMS when a key ARN is supplied (recommended for prod);
  # otherwise AES256 (AWS-managed). Immutable after creation.
  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name    = each.value
    Service = each.key
  }
}

# Optional resource-level access policy (defense in depth on top of caller IAM).
resource "aws_ecr_repository_policy" "this" {
  for_each = var.repository_policy_json == null ? {} : aws_ecr_repository.this

  repository = each.value.name
  policy     = var.repository_policy_json
}

# Keep only the most recent var.max_image_count images per repository.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${var.untagged_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expiry_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}
