resource "aws_route53_zone" "philomusica_hosted_zone" {
  name = var.domain_name
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
  zone_id         = aws_route53_zone.philomusica_hosted_zone.zone_id
}

resource "aws_route53_record" "url_ip4" {
  name    = var.domain_name
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "url_ip6" {
  name    = var.domain_name
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_ip4" {
  name    = "www.${var.domain_name}"
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_ip6" {
  name    = "www.${var.domain_name}"
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "certification_validation_local_region" {
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
  zone_id         = aws_route53_zone.philomusica_hosted_zone.zone_id
}

resource "aws_route53_record" "api_custom_domain" {
  name    = format("api.%s", var.domain_name)
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  type    = "A"
  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api_custom_domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_custom_domain.regional_zone_id
  }
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = 3
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  name    = "${element(aws_ses_domain_dkim.domain.dkim_tokens, count.index)}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.domain.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "email_record" {
  name    = var.domain_name
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  ttl     = "3600"
  type    = "MX"
  records = ["10 ${var.mx_domain_1}", "20 ${var.mx_domain_2}"]
}

resource "aws_route53_record" "spf_record" {
  name    = var.domain_name
  zone_id = aws_route53_zone.philomusica_hosted_zone.zone_id
  ttl     = "3600"
  type    = "TXT"
  records = ["v=spf1 include:${var.spf_domain} ~all", "google-site-verification=${var.google_site_verification_key}"]
}
