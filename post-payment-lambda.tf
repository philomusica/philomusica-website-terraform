resource "aws_lambda_permission" "apigw_lambda_post_payments" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_payment.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.stripe_webhook_post.http_method}${aws_api_gateway_resource.stripe_webhook.path}"
}

resource "aws_lambda_function" "post_payment" {
  filename      = data.archive_file.dummy_archive.output_path
  function_name = "philomusica-tickets-post-payment"
  role          = aws_iam_role.post_payment.arn
  handler       = "bin/main"
  runtime       = "go1.x"
  environment {
    variables = {
      CONCERTS_TABLE    = aws_dynamodb_table.concerts_table.name
      ORDERS_TABLE      = aws_dynamodb_table.orders_table.name
      STRIPE_SECRET     = var.stripe_webhook_secret
      REDEEM_TICKET_API = "https://api.philomusica.org.uk/redeem"
      SENDER_ADDRESS    = var.sender_address
    }
  }
}

resource "aws_iam_role" "post_payment" {
  name = "philomusica-get-post-payment-role"

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

resource "aws_cloudwatch_log_group" "post_payment_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.post_payment.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "post_payment_lambda_policy" {
  name = "post_payment_lambda_policy"
  path = "/"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ]
        Resource = ["${aws_dynamodb_table.orders_table.arn}", "${aws_dynamodb_table.concerts_table.arn}"]
        Effect   = "Allow"
        Sid      = "0"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.post_payment_log_group.arn}:*"
        Effect   = "Allow"
        Sid      = "1"
      },
      {
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail",
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "2"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "post_payment_lambda_policy_attachment" {
  role       = aws_iam_role.post_payment.name
  policy_arn = aws_iam_policy.post_payment_lambda_policy.arn
}
