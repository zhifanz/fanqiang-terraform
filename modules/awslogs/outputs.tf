output "agent_access_key" {
  sensitive = true
  value = {
    id     = aws_iam_access_key.default.id
    secret = aws_iam_access_key.default.secret
  }
}
output "arn" {
  value = aws_cloudwatch_log_group.default.arn
}
