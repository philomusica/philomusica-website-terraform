resource "aws_lambda_permission" "apigw_lambda_get_concerts" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_concerts.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.concerts.http_method}${aws_api_gateway_resource.concerts.path}"
}

resource "aws_lambda_function" "get_concerts" {
  filename = data.archive_file.dummy_archive.output_path
  function_name = "philomusica-tickets-get-concerts"
  role          = aws_iam_role.concerts.arn
  handler       = "bin/main"
  runtime       = "go1.x"
  environment {
	variables = {
	  CONCERTS_TABLE = aws_dynamodb_table.concerts_table.name
	  ORDERS_TABLE = aws_dynamodb_table.orders_table.name
	}
  }
}

resource "aws_iam_role" "concerts" {
  name = "philomusica-get-concerts-role"

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

resource "aws_iam_policy" "concerts_lambda_policy" {
  name = "concerts_lambda_policy"
  path = "/"
  policy = jsonencode({
    Statement = [
	  {
        Action = [
            "dynamodb:Scan",
            "dynamodb:GetItem",
        ]
        Resource = "${aws_dynamodb_table.concerts_table.arn}"
        Effect = "Allow"
        Sid = "1"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "concerts_lambda_policy_attachment" {
  role       = aws_iam_role.concerts.name
  policy_arn = aws_iam_policy.concerts_lambda_policy.arn
}
