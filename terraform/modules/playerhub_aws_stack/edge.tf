resource "aws_wafv2_web_acl" "regional" {
  count = var.enable_regional_waf ? 1 : 0

  name        = "${local.name}-regional-waf"
  description = "Regional WAF for ${local.name} application entry points"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-managed-common"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-known-bad-inputs"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = var.waf_rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-regional-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_cloudfront_origin_access_control" "static_site" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled && var.static_site.create_bucket ? 1 : 0

  name                              = "${local.name}-static-oac"
  description                       = "Origin access control for ${local.name} static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static_site" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled ? 1 : 0

  enabled             = true
  comment             = "${local.name} static site"
  default_root_object = "index.html"
  price_class         = var.static_site.price_class
  aliases             = var.static_site.aliases
  web_acl_id          = var.static_site.web_acl_id

  origin {
    domain_name              = var.static_site.create_bucket ? aws_s3_bucket.static_site[0].bucket_regional_domain_name : "${var.static_site.bucket_name}.s3.${data.aws_region.current.region}.amazonaws.com"
    origin_id                = "static-s3"
    origin_access_control_id = var.static_site.create_bucket ? aws_cloudfront_origin_access_control.static_site[0].id : null
  }

  default_cache_behavior {
    target_origin_id       = "static-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.static_site.acm_certificate_arn
    cloudfront_default_certificate = var.static_site.acm_certificate_arn == null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = var.static_site.acm_certificate_arn == null ? null : "sni-only"
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = length(var.static_site.aliases) == 0 || var.static_site.acm_certificate_arn != null
      error_message = "static_site.acm_certificate_arn is required when static_site.aliases is not empty."
    }

    precondition {
      condition     = var.static_site.create_bucket || var.static_site.bucket_name != null
      error_message = "static_site.bucket_name is required when static_site.create_bucket is false."
    }
  }
}

data "aws_iam_policy_document" "static_site_cloudfront" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled && var.static_site.create_bucket ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site[0].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_site[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site_cloudfront" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id
  policy = data.aws_iam_policy_document.static_site_cloudfront[0].json
}
