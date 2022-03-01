output "agent_access_key" {
  sensitive = true
  value     = aws_iam_access_key.default
}
output "artifacts_uri" {
  value = "s3://${aws_s3_bucket.default.bucket}/${local.artifacts_root_path}"
}
output "s3" {
  value = aws_s3_bucket.default
}
