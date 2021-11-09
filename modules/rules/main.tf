terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.134.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

resource "alicloud_api_gateway_group" "default" {
  name = alicloud_fc_service.default.name
  description = "Gateway group for fc ping"
}
resource "alicloud_api_gateway_api" "default" {
  name = alicloud_fc_function.default.name
  group_id = alicloud_api_gateway_group.default.id
  description = "Gateway for fc ping"
  auth_type = "ANONYMOUS"
  request_config {
    protocol = "HTTPS"
    method = "GET"
    path = "/fanqiang/ping"
    mode = "PASSTHROUGH"    
  }
  service_type = "FunctionCompute"
  fc_service_config {
    region = data.alicloud_regions.default.ids[0]
    function_name = alicloud_fc_function.default.name
    service_name = alicloud_fc_service.default.name
    arn_role = alicloud_ram_role.fc_invoke.arn
    timeout = alicloud_fc_function.default.timeout * 1000
  }
  stage_names = [ "RELEASE" ]
}
resource "alicloud_ram_role" "fc_invoke" {
  name     = var.ping_service.ram_role_name
  document = <<EOF
  {
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "apigateway.aliyuncs.com"
          ]
        }
      }
    ],
    "Version": "1"
  }
  EOF
  force    = true
}
resource "alicloud_ram_role_policy_attachment" "fc_invoke" {
  policy_name = "AliyunFCInvocationAccess"
  policy_type = "System"
  role_name   = alicloud_ram_role.fc_invoke.id
}
resource "alicloud_fc_service" "default" {
  name = var.ping_service.service_name
  internet_access = true
}
resource "alicloud_fc_function" "default" {
  service = alicloud_fc_service.default.id
  name = var.ping_service.function_name
  filename = data.archive_file.ping.output_path
  handler = "ping.handler"
  memory_size = 128
  runtime = "python3"
  timeout = var.ping_service.timeout
}
data "archive_file" "ping" {
  type = "zip"
  source_file = "${path.module}/scripts/ping.py"
  output_path = "${path.root}/.files/ping.zip"
}
data "alicloud_regions" "default" {
  current = true
}

resource "aws_lambda_function" "process_shadowsocks_logs" {
  function_name = var.log_process_service_name
  role = aws_iam_role.default.arn
  filename = data.archive_file.process_shadowsocks_logs.output_path
  handler = "process_shadowsocks_logs.handler"
  package_type = "Zip"
  runtime = "python3.9"
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.default.name
    }
  }
}
data "archive_file" "process_shadowsocks_logs" {
  type = "zip"
  source_file = "${path.module}/scripts/process_shadowsocks_logs.py"
  output_path = "${path.root}/.files/process_shadowsocks_logs.zip"
}
resource "aws_iam_role" "default" {
  name_prefix = "FanqiangLambdaRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess", "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"]
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.default.json
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
resource "aws_lambda_permission" "default" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_shadowsocks_logs.function_name
  principal     = "logs.${var.log_group.region}.amazonaws.com"
  source_arn    = "${var.log_group.arn}:*"
}
resource "aws_cloudwatch_log_subscription_filter" "default" {
  name = var.log_filter_name
  destination_arn = aws_lambda_function.process_shadowsocks_logs.arn
  filter_pattern = "DEBUG shadowsocks_service"
  log_group_name = var.log_group.name
}
resource "aws_dynamodb_table" "default" {
  name = "domains"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "name"
  attribute {
    name = "name"
    type = "S"
  }
}
