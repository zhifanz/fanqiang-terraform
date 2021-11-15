terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

resource "aws_cloudwatch_log_group" "default" {
  name              = var.log_group
  retention_in_days = 1
}
resource "aws_iam_user" "default" {
  name          = var.agent_user
  force_destroy = true
}
resource "aws_iam_user_policy" "default" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "logs:*"
      Resource = "${aws_cloudwatch_log_group.default.arn}:*"
    }]
  })
  user = aws_iam_user.default.name
}
resource "aws_iam_access_key" "default" {
  user = aws_iam_user.default.name
}
