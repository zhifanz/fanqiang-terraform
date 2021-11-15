output "config_path" {
  value = aws_s3_bucket_object.clash_config.key
}
output "rule_path" {
  value = aws_s3_bucket_object.clash_domestic_rule_provider.key
}
