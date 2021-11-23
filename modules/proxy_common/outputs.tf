output "agent_access_key" {
  sensitive = true
  value     = aws_iam_access_key.default
}
output "log_group_arn" {
  value = aws_cloudwatch_log_group.default.arn
}
output "shadowsocks_config_url" {
  value = "s3://${var.s3.bucket}/${aws_s3_bucket_object.shadowsocks_cfg.key}"
}

