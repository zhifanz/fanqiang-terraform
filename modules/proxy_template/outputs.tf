output "public_ip" {
  value = aws_lightsail_instance.default.public_ip_address
}
output "log_group_arn" {
  value = var.log_group != null ? aws_cloudwatch_log_group.default[0].arn : null
}