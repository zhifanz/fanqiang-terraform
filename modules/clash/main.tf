terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }
  }
}
resource "aws_s3_bucket_object" "clash_domestic_rule_provider" {
  bucket        = var.s3.bucket
  key           = "clash/domains_cn.yaml"
  acl           = "public-read"
  force_destroy = true
  content       = "payload: []"
}
resource "aws_s3_bucket_object" "clash_ap_rule_provider" {
  bucket        = var.s3.bucket
  key           = "clash/domains_ap.yaml"
  acl           = "public-read"
  force_destroy = true
  content       = "payload: []"
}
resource "aws_s3_bucket_object" "clash_eu_rule_provider" {
  bucket        = var.s3.bucket
  key           = "clash/domains_eu.yaml"
  acl           = "public-read"
  force_destroy = true
  content       = "payload: []"
}
resource "aws_s3_bucket_object" "clash_config" {
  bucket        = var.s3.bucket
  key           = "clash/config.yaml"
  force_destroy = true
  content = templatefile("${path.module}/config.yaml.tpl", {
    server    = var.client_config.server
    cipher    = var.client_config.cipher
    password  = var.client_config.password
    auto_port = var.client_config.port_mapping.default
    continent_rules = [
      {
        continent         = "ap"
        port              = var.client_config.port_mapping.ap
        rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_ap_rule_provider.key}"
      },
      {
        continent         = "eu"
        port              = var.client_config.port_mapping.eu
        rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_eu_rule_provider.key}"
      }
    ]
    domestic_rule_provider_url = "https://${var.s3.bucket_domain_name}/${aws_s3_bucket_object.clash_domestic_rule_provider.key}"
  })
}
data "external" "presign_url" {
  program = ["bash", "${path.module}/jsontify.sh", "aws", "s3", "presign", "s3://${var.s3.bucket}/${aws_s3_bucket_object.clash_config.key}"]
}
