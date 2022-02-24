terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}
locals {
  other_count = length(var.client_config.proxies.others)
}
resource "aws_s3_bucket_object" "domestic_clash_rule_provider" {
  count         = var.enable_rules ? 1 : 0
  bucket        = var.s3.bucket
  key           = "clash/domains_domestic.yaml"
  acl           = "public-read"
  force_destroy = true
  content       = "payload: []"
}
resource "aws_s3_bucket_object" "clash_rule_provider" {
  count         = local.other_count
  bucket        = var.s3.bucket
  key           = "clash/domains_${var.client_config.proxies.others[count.index].continent}.yaml"
  acl           = "public-read"
  force_destroy = true
  content       = "payload: []"
}
resource "aws_s3_bucket_object" "clash_config" {
  bucket        = var.s3.bucket
  key           = "clash/config.yaml"
  acl           = "public-read"
  force_destroy = true
  content = var.enable_rules ? templatefile("${path.module}/config-rule.yaml.tpl", {
    domestic_rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.domestic_clash_rule_provider[0].key}"
    other_rule_provider_urls   = [for e in aws_s3_bucket_object.clash_rule_provider : "https://${var.s3.bucket_domain_name}/${e.key}"]
    config                     = var.client_config
    }) : templatefile("${path.module}/config-base.yaml.tpl", {
    config = var.client_config
  })
}
