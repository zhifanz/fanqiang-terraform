output "agent_access_key" {
  sensitive = true
  value     = aws_iam_access_key.default
}
output "shadowsocks_config_uri" {
  value = "s3://${aws_s3_bucket.default.bucket}/${aws_s3_bucket_object.shadowsocks_cfg.key}"
}
output "s3" {
  value = aws_s3_bucket.default
}
