terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.134.0"
    }
  }
}

provider "aws" {
  region = var.proxy_region
}
provider "alicloud" {
  region = var.tunnel_region
}

module "proxy" {
  source               = "./modules/awsecs"
  port                 = var.port
  encryption_algorithm = var.encryption_algorithm
  password             = var.password
}

module "tunnel" {
  source          = "./modules/tunnel"
  proxy_port      = var.port
  proxy_public_ip = module.proxy.public_ip
  public_key      = var.public_key
}

module "rules" {
  source = "./modules/rules"
  log_group = module.proxy.log_group
}

resource "aws_s3_bucket" "default" {
  bucket        = var.bucket
  acl           = "public-read"
  force_destroy = true
}

resource "aws_s3_bucket_object" "clash_config" {
  bucket = aws_s3_bucket.default.id
  key = local.clash_config_key
  acl = "public-read"
  force_destroy = true
  content = templatefile("${path.module}/clash-config.yml.tpl", {
    server = module.tunnel.public_ip
    port = var.port
    cipher = var.encryption_algorithm
    password = var.password
  })
}

locals {
  clash_config_key = "clash/config.yaml"
}
