resource "aws_ecr_repository" "app" {
  for_each = var.app_repositories

  name                 = "${local.name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the most recent 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "private" {
  for_each = var.s3_buckets

  bucket        = "${local.name}-${each.key}-${data.aws_region.current.region}"
  force_destroy = each.value.force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.name}-${each.key}"
  })
}

resource "aws_s3_bucket_public_access_block" "private" {
  for_each = aws_s3_bucket.private

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  versioning_configuration {
    status = var.s3_buckets[each.key].versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  rule {
    id     = "expire-old-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.s3_buckets[each.key].lifecycle_days
    }
  }
}

resource "aws_s3_bucket" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket        = coalesce(var.static_site.bucket_name, "${local.name}-static-${data.aws_region.current.region}")
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = "${local.name}-static"
  })
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.static_site[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
