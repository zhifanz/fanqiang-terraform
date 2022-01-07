terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}
resource "aws_s3_bucket_object" "clash_rule_provider" {
  count         = length(var.client_config.port_mapping.others) + 1
  bucket        = var.s3.bucket
  key           = count.index == 0 ? "clash/domains_domestic.yaml" : "clash/domains_${var.client_config.port_mapping.others[count.index - 1].continent}.yaml"
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
    server    = var.client_config.server
    cipher    = var.client_config.cipher
    password  = var.client_config.password
    auto_port = var.client_config.port_mapping.auto
    continent_rules = [for i, v in var.client_config.port_mapping.others : {
      continent         = v.continent
      port              = v.port
      rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_rule_provider[i + 1].key}"
    }]
    domestic_rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_rule_provider[0].key}"
  })
}
