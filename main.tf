provider "aws" {
	region = var.aws_region
}

provider "aws" {
    region = "us-east-1"
    alias = "acm_provider"
}

terraform {
	backend "s3" {
		bucket = "philo-web-terraform-state"
		key = "philomusica.tfstate"
		region = "eu-west-1"
	}
}

resource "aws_s3_bucket" "philomusica_website" {
	bucket = "philomusica-website"
	acl = "private"
	website {
		index_document = "index.html"
		error_document = "error.html"
	}
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
	bucket = aws_s3_bucket.philomusica_website.id

	policy = jsonencode({
		Version = "2012-10-17",
		Id      = "PhilomusicaS3BucketPolicy",
		Statement = [
			{
                Sid = "1",
                Effect = "Allow",
                Principal = {
                    AWS = aws_cloudfront_origin_access_identity.philomusica_website_access_identity.iam_arn
                },
                Action = "s3:GetObject",
                Resource = "${aws_s3_bucket.philomusica_website.arn}/*"
			}                                                                                              
		],
	})
}

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

  aliases = ["${var.domain_name}", "www.${var.domain_name}"]

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


  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}

resource "aws_cloudfront_origin_access_identity" "philomusica_website_access_identity" {
  comment = "Origin access identity for the Philomusica website"
}

data "aws_route53_zone" "philomusica_hosted_zone" {
    name = "${var.domain_name}"
}

resource "aws_acm_certificate" "cert" {
    provider = aws.acm_provider
    domain_name = var.domain_name
    subject_alternative_names = ["*.${var.domain_name}"]
    validation_method = "DNS"
}

resource "aws_route53_record" "certification_validation" {
    for_each = {
        for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
          name   = dvo.resource_record_name
          record = dvo.resource_record_value
          type   = dvo.resource_record_type
        }
    }

    allow_overwrite = true
    name            = each.value.name
    records         = [each.value.record]
    ttl             = 60
    type            = each.value.type
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
    provider = aws.acm_provider
    certificate_arn = aws_acm_certificate.cert.arn
    validation_record_fqdns = [for record in aws_route53_record.certification_validation : record.fqdn]
}

resource "aws_route53_record" "url_ip4" {
    name = "${var.domain_name}"
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
    type = "A"

    alias {
        name = aws_cloudfront_distribution.s3_distribution.domain_name
        zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
        evaluate_target_health = false
    }
}

resource "aws_route53_record" "url_ip6" {
    name = "${var.domain_name}"
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
    type = "AAAA"

    alias {
        name = aws_cloudfront_distribution.s3_distribution.domain_name
        zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
        evaluate_target_health = false
    }
}

resource "aws_route53_record" "www_ip4" {
    name = "www.${var.domain_name}"
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
    type = "A"

    alias {
        name = aws_cloudfront_distribution.s3_distribution.domain_name
        zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
        evaluate_target_health = false
    }
}

resource "aws_route53_record" "www_ip6" {
    name = "www.${var.domain_name}"
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
    type = "AAAA"

    alias {
        name = aws_cloudfront_distribution.s3_distribution.domain_name
        zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
        evaluate_target_health = false
    }
}
