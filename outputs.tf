output "clash_config_url" {
  value = "https://${aws_s3_bucket.default.bucket_domain_name}/${aws_s3_bucket_object.clash_config.key}"
}
