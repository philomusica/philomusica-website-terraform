resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.philomusica_website.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.philomusica_website.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.philomusica_website_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.philomusica_website.bucket_regional_domain_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/members-info"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.philomusica_website.bucket_regional_domain_name

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.lambda_edge.qualified_arn
    }

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/secure/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.philomusica_website.bucket_regional_domain_name

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.lambda_edge.qualified_arn
    }

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 86400
  }
  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}

resource "aws_cloudfront_origin_access_identity" "philomusica_website_access_identity" {
  comment = "Origin access identity for the Philomusica website"
}

resource "aws_cloudfront_distribution" "s3_distribution_redirect" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.philomusica_website_config_redirect.website_endpoint
    origin_id   = aws_s3_bucket_website_configuration.philomusica_website_config_redirect.website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"

      http_port  = "80"
      https_port = "443"

      # TODO: given the origin_protocol_policy set to `http-only`,
      # not sure what this does...
      # "If the origin is an Amazon S3 bucket, CloudFront always uses TLSv1.2."
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = ["www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket_website_configuration.philomusica_website_config_redirect.website_endpoint

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_origin_access_identity" "philomusica_website_access_identity_redirect" {
  comment = "Origin access identity for the Philomusica website redirect"
}
