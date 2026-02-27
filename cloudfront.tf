# CloudFront distribution for global content delivery

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cloudfront ? 1 : 0

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for ${local.name_prefix}"
  price_class     = "PriceClass_100"
  http_version    = "http2and3"

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.ssl_certificate_arn != "" ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    origin_shield {
      enabled              = true
      origin_shield_region = var.aws_region
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb-origin"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Accept", "Accept-Language"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = var.ssl_certificate_arn != "" ? "redirect-to-https" : "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.ssl_certificate_arn == ""
    acm_certificate_arn            = var.ssl_certificate_arn != "" ? var.ssl_certificate_arn : null
    ssl_support_method             = var.ssl_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.ssl_certificate_arn != "" ? "TLSv1.2_2021" : "TLSv1"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cloudfront"
    }
  )
}

# CloudWatch Log Group for CloudFront logs (optional)
resource "aws_cloudwatch_log_group" "cloudfront" {
  count = var.enable_cloudfront ? 1 : 0

  name              = "/aws/cloudfront/${local.name_prefix}"
  retention_in_days = 7

  tags = local.common_tags
}
