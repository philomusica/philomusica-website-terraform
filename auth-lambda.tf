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

resource "aws_lambda_function" "lambda_edge" {
  filename      = data.archive_file.dummy_archive.output_path
  function_name = "philo_auth_lambda"
  role          = aws_iam_role.lambda_edge_iam_role.arn
  handler       = "index.handler"
  provider      = aws.us_east_1
  publish       = true
  runtime       = "nodejs18.x"
}

resource "aws_cloudwatch_log_group" "lambda_edge_log_group" {
  name              = format("/aws/lambda/%s", aws_lambda_function.lambda_edge.function_name)
  retention_in_days = 14
}

