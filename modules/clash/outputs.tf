output "config_url" {
  value = data.external.presign_url.result.stdout
}
output "rule_path" {
  value = aws_s3_bucket_object.clash_domestic_rule_provider.key
}
