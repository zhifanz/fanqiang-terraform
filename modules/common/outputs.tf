output "agent_access_key" {
  sensitive = true
  value     = aws_iam_access_key.default
}
output "artifacts" {
  value = {
    root_path    = local.artifacts_root_path
    root_uri     = "s3://${aws_s3_bucket.default.bucket}/proxy"
    compose_file = "docker-compose.yml"
  }
}
output "s3" {
  value = aws_s3_bucket.default
}
