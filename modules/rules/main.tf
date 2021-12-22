terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }
  }
}

resource "aws_ecr_repository" "update_rules" {
  name = var.update_rules_service.docker_repo.name
}
data "external" "update_rules" {
  program = ["bash",
    "${path.root}/run-script.sh",
    "${path.module}/create-ecr-image.sh",
    "${var.update_rules_service.docker_repo.registry}/${var.update_rules_service.docker_repo.name}:${var.update_rules_service.docker_repo.version}",
    "${aws_ecr_repository.update_rules.repository_url}:latest"
  ]
}
resource "aws_lambda_function" "update_rules" {
  function_name = var.update_rules_service.name
  role          = aws_iam_role.default.arn
  package_type  = "Image"
  runtime       = "python3.8"
  image_uri     = "${aws_ecr_repository.update_rules.repository_url}:latest"
  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.default.name
      BUCKET           = var.update_rules_service.rules_storage.bucket
      CONFIG_ROOT_PATH = var.update_rules_service.rules_storage.config_root_path
      DAYS_TO_SCAN     = var.update_rules_service.days_to_scan
    }
  }
  depends_on = [data.external.update_rules]
}
resource "aws_cloudwatch_log_group" "update_rules" {
  name              = "/aws/lambda/${aws_lambda_function.update_rules.function_name}"
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

resource "aws_ecr_repository" "process_shadowsocks_logs" {
  name = var.process_shadowsocks_logs_service.docker_repo.name
}
data "external" "process_shadowsocks_logs" {
  program = ["bash",
    "${path.root}/run-script.sh",
    "${path.module}/create-ecr-image.sh",
    "${var.process_shadowsocks_logs_service.docker_repo.registry}/${var.process_shadowsocks_logs_service.docker_repo.name}:${var.process_shadowsocks_logs_service.docker_repo.version}",
    "${aws_ecr_repository.process_shadowsocks_logs.repository_url}:latest"
  ]
}
resource "aws_lambda_function" "process_shadowsocks_logs" {
  function_name = var.process_shadowsocks_logs_service.name
  role          = aws_iam_role.default.arn
  package_type  = "Image"
  runtime       = "python3.8"
  image_uri     = "${aws_ecr_repository.process_shadowsocks_logs.repository_url}:latest"
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.default.name
    }
  }
  depends_on = [data.external.process_shadowsocks_logs]
}
resource "aws_lambda_permission" "process_shadowsocks_logs" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_shadowsocks_logs.function_name
  principal     = "logs.${var.process_shadowsocks_logs_service.log_group.region}.amazonaws.com"
  source_arn    = "${var.process_shadowsocks_logs_service.log_group.arn}:*"
}
resource "aws_cloudwatch_log_group" "process_shadowsocks_logs" {
  name              = "/aws/lambda/${aws_lambda_function.process_shadowsocks_logs.function_name}"
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
