output "public_ip" {
  value = module.tunnel.public_ip
}
output "clash_config_url" {
  value = "https://${aws_s3_bucket.default.bucket_domain_name}/${local.clash_config_key}"
}
