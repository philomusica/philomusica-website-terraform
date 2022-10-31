resource "aws_api_gateway_base_path_mapping" "api_custom_domain" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = format("api.%s", var.domain_name)
  stage_name = aws_api_gateway_stage.api.stage_name
  depends_on = [aws_api_gateway_deployment.api]
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

resource "aws_api_gateway_rest_api" "api" {
  name = "philomusica-website"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "contact" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "contact-us"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "contact_options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.contact.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
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
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contact_options.http_method
    type          = "MOCK"
    depends_on = [aws_api_gateway_method.contact_options]
	request_templates = {
	  "application/json" = jsonencode(
        {
		  statusCode = 200
		}
	  )
	}
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contact_options.http_method
    status_code   = aws_api_gateway_method_response.options_200.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }

	response_templates = {
	  "application/json" = "Empty"
	}
    depends_on = [aws_api_gateway_method_response.options_200]
}

resource "aws_api_gateway_method" "contact" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.contact.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
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
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.contact.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.contact.invoke_arn
  depends_on = [aws_api_gateway_method.contact]
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on = [aws_api_gateway_integration.contact_post]
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "philomusica"
}

resource "aws_api_gateway_resource" "concerts" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "concerts"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "concerts" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.concerts.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "concerts" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.concerts.id
  http_method          = aws_api_gateway_method.concerts.http_method
  integration_http_method = "POST"
  type                 = "AWS_PROXY"
  uri = aws_lambda_function.get_concerts.invoke_arn
}

resource "aws_api_gateway_method_response" "concert" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.concerts.id
  http_method = aws_api_gateway_method.concerts.http_method
  status_code = "200"
}

resource "aws_api_gateway_resource" "buy_tickets" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "buy-tickets"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "buy_tickets_options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.buy_tickets.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method_response" "buy_tickets_options_200" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.buy_tickets.id
  http_method   = aws_api_gateway_method.buy_tickets_options.http_method
  status_code   = "200"
  response_models = {
        "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.buy_tickets_options]
}

resource "aws_api_gateway_integration" "buy_tickets_options_integration" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.buy_tickets.id
    http_method   = aws_api_gateway_method.buy_tickets_options.http_method
    type          = "MOCK"
    depends_on = [aws_api_gateway_method.buy_tickets_options]
	request_templates = {
	  "application/json" = jsonencode(
        {
		  statusCode = 200
		}
	  )
	}
}

resource "aws_api_gateway_integration_response" "buy_tickets_options_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.buy_tickets.id
    http_method   = aws_api_gateway_method.buy_tickets_options.http_method
    status_code   = aws_api_gateway_method_response.buy_tickets_options_200.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }

	response_templates = {
	  "application/json" = "Empty"
	}
    depends_on = [aws_api_gateway_method_response.buy_tickets_options_200]
}

resource "aws_api_gateway_method" "buy_tickets" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.buy_tickets.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method_response" "buy_tickets_cors_method_response_200" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.buy_tickets.id
    http_method   = aws_api_gateway_method.buy_tickets.http_method
    status_code   = "200"
	response_models = {
	  "application/json" = "Empty"
	}
	response_parameters = {
	  "method.response.header.Access-Control-Allow-Origin" = true
	}
    depends_on = [aws_api_gateway_method.buy_tickets]
}

resource "aws_api_gateway_integration" "buy_tickets_post" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.buy_tickets.id
  http_method             = aws_api_gateway_method.buy_tickets.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.buy_tickets.invoke_arn
  depends_on = [aws_api_gateway_method.buy_tickets]
}
