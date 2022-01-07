output "config_url" {
  value = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_config.key}"
}
