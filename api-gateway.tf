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
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
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
    depends_on = [aws_api_gateway_method_response.options_200]
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

resource "aws_api_gateway_integration" "contact_post" {
  rest_api_id             = aws_api_gateway_rest_api.contact.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.contact.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact.invoke_arn
  depends_on = [aws_api_gateway_method.contact]
}

resource "aws_api_gateway_deployment" "contact" {
  rest_api_id = aws_api_gateway_rest_api.contact.id
  depends_on = [aws_api_gateway_integration.contact_post]
}

resource "aws_api_gateway_stage" "contact" {
  deployment_id = aws_api_gateway_deployment.contact.id
  rest_api_id   = aws_api_gateway_rest_api.contact.id
  stage_name    = "philomusica"
}
