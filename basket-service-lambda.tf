resource "aws_lambda_permission" "apigw_lambda_basket_service" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.basket_service.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.order_post.http_method}${aws_api_gateway_resource.order.path}"
}

resource "aws_lambda_function" "basket_service" {
  filename      = data.archive_file.dummy_archive.output_path
  function_name = "philomusica-tickets-basket-service"
  role          = aws_iam_role.basket_service.arn
  handler       = "bin/main"
  runtime       = "go1.x"
  environment {
    variables = {
      TABLE_NAME = "changeme"
    }
  }
  lifecycle {
    ignore_changes = [environment[0].variables]
  }
}

resource "aws_iam_role" "basket_service" {
  name = "philomusica-get-basket-service-role"

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

resource "aws_iam_policy" "basket_service_lambda_policy" {
  name = "basket_service_lambda_policy"
  path = "/"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
        ]
        Resource = "${aws_dynamodb_table.orders_table.arn}"
        Effect   = "Allow"
        Sid      = "1"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "basket_service_lambda_policy_attachment" {
  role       = aws_iam_role.basket_service.name
  policy_arn = aws_iam_policy.basket_service_lambda_policy.arn
}
