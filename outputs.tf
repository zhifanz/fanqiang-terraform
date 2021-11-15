output "clash_config_url" {
  value = "https://${aws_s3_bucket.default.bucket_domain_name}/${module.clash.config_path}"
}
