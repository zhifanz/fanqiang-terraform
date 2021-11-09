output "public_ip" {
  value = data.aws_network_interface.default.association[0].public_ip
}
output "log_group" {
  value = {
    name = aws_cloudwatch_log_group.default.name
    arn = aws_cloudwatch_log_group.default.arn
    region = data.aws_region.default.name
  }
}
