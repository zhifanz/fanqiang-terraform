terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}
resource "aws_s3_bucket_object" "clash_domestic_rule_provider" {
  bucket        = var.s3.bucket
  key           = "clash/direct_domains.yaml"
  acl           = "public-read"
  force_destroy = true
  content       = "payload: []"
}
resource "aws_s3_bucket_object" "clash_config" {
  bucket        = var.s3.bucket
  key           = "clash/config.yaml"
  acl           = "public-read"
  force_destroy = true
  content = templatefile("${path.module}/config.yaml.tpl", {
    server                     = var.client_config.server
    port                       = var.client_config.port
    cipher                     = var.client_config.cipher
    password                   = var.client_config.password
    domestic_rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_domestic_rule_provider.key}"
  })
}
