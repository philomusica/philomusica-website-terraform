resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.contact_post.http_method}${aws_api_gateway_resource.contact.path}"
}

resource "aws_lambda_function" "contact" {
  filename      = data.archive_file.dummy_archive.output_path
  function_name = "philomusica-contact-form"
  role          = aws_iam_role.contact.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  environment {
    variables = {
      RECAPTCHA_SECRET = "changeme"
      RECEIVER         = "changeme"
      SENDER           = "changeme"
    }
  }
  lifecycle {
    ignore_changes = [environment[0].variables]
  }
}

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
        Effect   = "Allow"
        Resource = "*"
        Sid      = "1"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "contact_lambda_policy_attachment" {
  role       = aws_iam_role.contact.name
  policy_arn = aws_iam_policy.contact_lambda_policy.arn
}
