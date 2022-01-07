terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
}

resource "null_resource" "download_fanqiang_analysis" {
  provisioner "local-exec" {
    command = "curl --location -o analysis.zip https://github.com/zhifanz/fanqiang-analysis/releases/download/v1.0.0/fanqiang-analysis-v1.0.0.zip"
  }
}
resource "aws_lambda_function" "update_rules" {
  function_name = var.update_rules_service.name
  role          = aws_iam_role.default.arn
  package_type  = "Zip"
  runtime       = "python3.9"
  filename      = "analysis.zip"
  handler       = "calculate_routing_rules.handler"
  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.default.name
      BUCKET           = var.update_rules_service.rules_storage.bucket
      CONFIG_ROOT_PATH = var.update_rules_service.rules_storage.config_root_path
      DAYS_TO_SCAN     = var.update_rules_service.days_to_scan
      CONTINENTS       = "eu,ap"
    }
  }
  depends_on = [
    null_resource.download_fanqiang_analysis, aws_cloudwatch_log_group.update_rules
  ]
}
resource "aws_cloudwatch_log_group" "update_rules" {
  name              = "/aws/lambda/${var.update_rules_service.name}"
  retention_in_days = 1
}
resource "aws_lambda_permission" "update_rules" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_rules.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default.arn
}
resource "aws_cloudwatch_event_rule" "default" {
  schedule_expression = "rate(${var.update_rules_service.update_interval})"
  is_enabled          = true
}
resource "aws_cloudwatch_event_target" "default" {
  rule = aws_cloudwatch_event_rule.default.id
  arn  = aws_lambda_function.update_rules.arn
}

resource "aws_lambda_function" "process_shadowsocks_logs" {
  function_name = var.process_shadowsocks_logs_service.name
  role          = aws_iam_role.default.arn
  package_type  = "Zip"
  runtime       = "python3.9"
  filename      = "analysis.zip"
  handler       = "process_aws_cloudwatch_shadowsocks_logs.handler"
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.default.name
    }
  }
  depends_on = [null_resource.download_fanqiang_analysis, aws_cloudwatch_log_group.process_shadowsocks_logs]
}
resource "aws_lambda_permission" "process_shadowsocks_logs" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_shadowsocks_logs.function_name
  principal     = "logs.${var.process_shadowsocks_logs_service.log_group.region}.amazonaws.com"
  source_arn    = "${var.process_shadowsocks_logs_service.log_group.arn}:*"
}
resource "aws_cloudwatch_log_group" "process_shadowsocks_logs" {
  name              = "/aws/lambda/${var.process_shadowsocks_logs_service.name}"
  retention_in_days = 1
}
resource "aws_cloudwatch_log_subscription_filter" "default" {
  name            = var.process_shadowsocks_logs_service.log_filter_name
  destination_arn = aws_lambda_function.process_shadowsocks_logs.arn
  filter_pattern  = "DEBUG shadowsocks_service"
  log_group_name  = var.process_shadowsocks_logs_service.log_group.name
}
resource "aws_iam_role" "default" {
  name_prefix = "FanqiangLambdaRole"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.default.json
}
data "aws_iam_policy_document" "default" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_dynamodb_table" "default" {
  name         = var.domain_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "domainName"
  attribute {
    name = "domainName"
    type = "S"
  }
}
resource "aws_iam_user_policy" "default" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "dynamodb:*"
        Resource = aws_dynamodb_table.default.arn
      }
    ]
  })
  user = var.agent_user
}
