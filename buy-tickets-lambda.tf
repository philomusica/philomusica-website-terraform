resource "aws_lambda_permission" "apigw_lambda_buy_tickets" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.buy_tickets.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.buy_tickets.http_method}${aws_api_gateway_resource.buy_tickets.path}"
}

resource "aws_lambda_function" "buy_tickets" {
  filename = data.archive_file.dummy_archive.output_path
  function_name = "philomusica-tickets-buy-tickets"
  role          = aws_iam_role.buy_tickets.arn
  handler       = "bin/main"
  runtime       = "go1.x"
  environment {
	variables = {
	  TABLE_NAME = "changeme"
	}
  }
  lifecycle {
	ignore_changes = [ environment[0].variables ]
  }
}

resource "aws_iam_role" "buy_tickets" {
  name = "philomusica-get-buy-tickets-role"

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

resource "aws_iam_policy" "buy_tickets_lambda_policy" {
  name = "buy_tickets_lambda_policy"
  path = "/"
  policy = jsonencode({
    Statement = [
	  {
        Action = [
            "dynamodb:Scan",
            "dynamodb:GetItem",
        ]
        Resource = "${aws_dynamodb_table.concert_tickets_table.arn}"
        Effect = "Allow"
        Sid = "1"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "buy_tickets_lambda_policy_attachment" {
  role       = aws_iam_role.buy_tickets.name
  policy_arn = aws_iam_policy.buy_tickets_lambda_policy.arn
}
