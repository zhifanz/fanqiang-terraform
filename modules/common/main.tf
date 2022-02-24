terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}
locals {
  artifacts_root_path = "proxy"
}
resource "aws_s3_bucket" "default" {
  bucket        = var.bucket
  force_destroy = true
}
resource "aws_s3_bucket_object" "shadowsocks_cfg" {
  bucket        = aws_s3_bucket.default.bucket
  key           = "${local.artifacts_root_path}/config.json"
  force_destroy = true
  content = jsonencode({
    server      = "::"
    server_port = var.shadowsocks.server_port
    password    = var.shadowsocks.password
    method      = var.shadowsocks.method
  })
}
resource "aws_s3_bucket_object" "docker_compose_file" {
  bucket        = aws_s3_bucket.default.bucket
  key           = "${local.artifacts_root_path}/docker-compose.yml"
  force_destroy = true
  content = templatefile("${path.module}/docker-compose.yml.tpl", {
    port = var.shadowsocks.server_port
  })
}
resource "aws_iam_user" "default" {
  name          = var.agent_user
  force_destroy = true
}
resource "aws_iam_user_policy" "default" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.default.arn}/*"
      }
    ]
  })
  user = aws_iam_user.default.name
}
resource "aws_iam_access_key" "default" {
  user = aws_iam_user.default.name
}
