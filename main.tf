provider "aws" {
	region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
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

  ordered_cache_behavior {
    path_pattern     = "/members-info.html"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.philomusica_website.bucket_regional_domain_name

	lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = "${aws_lambda_function.lambda_edge.qualified_arn}"
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
      lambda_arn = "${aws_lambda_function.lambda_edge.qualified_arn}"
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

resource "aws_acm_certificate" "cert_local_region" {
    domain_name = var.domain_name
    subject_alternative_names = ["*.${var.domain_name}"]
    validation_method = "DNS"
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
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation_local_region" {
    certificate_arn = aws_acm_certificate.cert_local_region.arn
    validation_record_fqdns = [for record in aws_route53_record.certification_validation_local_region : record.fqdn]
}

resource "aws_route53_record" "api_custom_domain" {
    name = format("api.%s", var.domain_name)
    zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
    type = "A"
	alias {
      evaluate_target_health = true
      name                   = aws_api_gateway_domain_name.api_custom_domain.regional_domain_name
      zone_id                = aws_api_gateway_domain_name.api_custom_domain.regional_zone_id
   }
}

resource "aws_api_gateway_base_path_mapping" "api_custom_domain" {
  api_id      = aws_api_gateway_rest_api.contact.id
  domain_name = format("api.%s", var.domain_name)
  stage_name  = "philomusica"
}

resource "aws_api_gateway_domain_name" "api_custom_domain" {
  domain_name              = format("api.%s", var.domain_name)
  regional_certificate_arn = aws_acm_certificate_validation.cert_validation_local_region.certificate_arn

  endpoint_configuration {
	types = [
      "REGIONAL",
    ]
  }
}

resource "aws_iam_role" "lambda_edge_iam_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "lambda_edge_policy_document" {
  statement {
    sid = "1"

    actions = [
	  "logs:CreateLogGroup",
	  "logs:CreateLogStream",
	  "logs:PutLogEvents"
    ]

    resources = [
	  "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_edge_policy" {
  name   = "lambda_edge_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_edge_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_edge_policy_attachment" {
  role       = aws_iam_role.lambda_edge_iam_role.name
  policy_arn = aws_iam_policy.lambda_edge_policy.arn
}

data "archive_file" "dummy_archive" {
  type        = "zip"
  output_path = "${path.module}/function.zip"

  source {
    content  = "This is a dummy zip file"
    filename = "dummy.txt"
  }
}

resource "aws_lambda_function" "lambda_edge" {
	filename = data.archive_file.dummy_archive.output_path
	function_name = "philo_auth_lambda"
	role = aws_iam_role.lambda_edge_iam_role.arn
	handler = "index.handler"
	provider = aws.us_east_1
	publish  = true
	runtime = "nodejs12.x"
}

resource "aws_cloudwatch_log_group" "lambda_edge_log_group" {
  name = format("/aws/lambda/%s", aws_lambda_function.lambda_edge.function_name)
  retention_in_days = 14
}

resource "aws_api_gateway_rest_api" "contact" {
  name = "philomusica-contact-us"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "contact" {
  parent_id   = aws_api_gateway_rest_api.contact.root_resource_id
  path_part   = "contact-us"
  rest_api_id = aws_api_gateway_rest_api.contact.id
}

resource "aws_api_gateway_method" "contact_options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.contact.id
  rest_api_id   = aws_api_gateway_rest_api.contact.id
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id   = aws_api_gateway_rest_api.contact.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = aws_api_gateway_method.contact_options.http_method
  status_code   = "200"
  response_models = {
        "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.contact_options]
}

resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = aws_api_gateway_rest_api.contact.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contact_options.http_method
    type          = "MOCK"
    depends_on = [aws_api_gateway_method.contact_options]
	passthrough_behavior = "WHEN_NO_MATCH"
	request_templates = {
	  "application/json" = jsonencode({
	    statusCode = 200
	  })
	}
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.contact.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contact_options.http_method
    status_code   = aws_api_gateway_method_response.options_200.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
	response_templates = {
	  "application/json" = ""
	}
    depends_on = [aws_api_gateway_method_response.options_200, aws_api_gateway_integration.options_integration]
}

resource "aws_api_gateway_method" "contact" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.contact.id
  rest_api_id   = aws_api_gateway_rest_api.contact.id
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
    rest_api_id   = aws_api_gateway_rest_api.contact.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contact.http_method
    status_code   = "200"
	response_models = {
	  "application/json" = "Empty"
	}
	response_parameters = {
	  "method.response.header.Access-Control-Allow-Origin" = true
	}
    depends_on = [aws_api_gateway_method.contact]
}

resource "aws_api_gateway_integration_response" "contact_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.contact.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contact.http_method
    status_code   = aws_api_gateway_method_response.cors_method_response_200.status_code
	response_parameters = {
	  "method.response.header.Access-Control-Allow-Origin" = "'*'"
	}
    depends_on = [aws_api_gateway_method_response.cors_method_response_200]
}

resource "aws_api_gateway_integration" "contact_post" {
  rest_api_id             = aws_api_gateway_rest_api.contact.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.contact.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact.invoke_arn
}

resource "aws_api_gateway_deployment" "contact" {
  rest_api_id = aws_api_gateway_rest_api.contact.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contact.id,
      aws_api_gateway_method.contact_options.id,
      aws_api_gateway_method.contact.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_integration.contact_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "contact" {
  deployment_id = aws_api_gateway_deployment.contact.id
  rest_api_id   = aws_api_gateway_rest_api.contact.id
  stage_name    = "philomusica"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.contact.id}/*/${aws_api_gateway_method.contact.http_method}${aws_api_gateway_resource.contact.path}"
}

resource "aws_lambda_function" "contact" {
  filename = data.archive_file.dummy_archive.output_path
  function_name = "philomusica-contact-form"
  role          = aws_iam_role.contact.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  environment {
	variables = {
	  RECAPTCHA_SECRET = "changeme"
      RECEIVER = "changeme"
	  SENDER = "changeme"
	}
  }
}

# IAM
resource "aws_iam_role" "contact" {
  name = "philomusica-contact-form-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "contact_lambda_policy" {
  name = "contact_lambda_policy"
  path = "/"
  policy = jsonencode({
    Statement = [
	  {
        Action = [
			"ses:SendRawEmail",
            "ses:SendEmail",
        ]
        Effect = "Allow"
        Resource = "*"
        Sid = "1"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "contact_lambda_policy_attachment" {
  role       = aws_iam_role.contact.name
  policy_arn = aws_iam_policy.contact_lambda_policy.arn
}

resource "aws_ses_domain_identity" "domain" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "domain" {
  domain = aws_ses_domain_identity.domain.domain
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.philomusica_hosted_zone.zone_id
  name    = "${element(aws_ses_domain_dkim.domain.dkim_tokens, count.index)}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.domain.dkim_tokens, count.index)}.dkim.amazonses.com"]
}
